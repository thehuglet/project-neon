const std = @import("std");

const ComponentRegistry = @import("component").Registry;

pub const EntityId = @import("entity_id_pool.zig").EntityId;
const EntityIdPool = @import("entity_id_pool.zig").EntityIdPool;
const SparseComponentSet = @import("sparse_component_set.zig").SparseComponentSet;

const ComponentTag = blk: {
    var enum_fields: [ComponentRegistry.len]std.builtin.Type.EnumField = undefined;
    for (ComponentRegistry, 0..) |entry, i| {
        enum_fields[i] = .{
            .name = entry.field_name,
            .value = i,
        };
    }
    break :blk @Type(.{
        .@"enum" = .{
            .tag_type = u8,
            .fields = enum_fields[0..],
            .decls = &.{},
            .is_exhaustive = true,
        },
    });
};

const ComponentUnion = blk: {
    const field_count = ComponentRegistry.len;
    var fields: [field_count]std.builtin.Type.UnionField = undefined;
    for (ComponentRegistry, 0..) |entry, i| {
        fields[i] = .{
            .name = entry.field_name,
            .type = entry.component_type,
            .alignment = @alignOf(entry.component_type),
        };
    }
    break :blk @Type(.{
        .@"union" = .{
            .layout = .auto,
            .tag_type = ComponentTag,
            .fields = fields[0..],
            .decls = &.{},
        },
    });
};

const ComponentState = blk: {
    const field_count = ComponentRegistry.len;
    var fields: [field_count]std.builtin.Type.StructField = undefined;
    for (ComponentRegistry, 0..) |entry, i| {
        const FieldType = SparseComponentSet(entry.component_type);
        fields[i] = .{
            .name = entry.field_name,
            .type = FieldType,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(FieldType),
        };
    }
    break :blk @Type(.{
        .@"struct" = .{
            .layout = .auto,
            .fields = fields[0..],
            .decls = &.{},
            .is_tuple = false,
        },
    });
};

const Operation = union(enum) {
    add_component: struct { entity_id: EntityId, component: ComponentUnion },
    remove_component: struct { entity_id: EntityId, tag: ComponentTag },
    delete_entity: struct { entity_id: EntityId },
};

pub fn Query(comptime ComponentTypes: anytype) type {
    return struct {
        const Self = @This();

        ecs: *ECS,
        candidate_component_lists: [ComponentTypes.len]*std.ArrayList(u32),
        primary_index: usize,
        index: usize,

        pub fn init(ecs: *ECS) Self {
            var smallest_size: usize = std.math.maxInt(u32);
            var best_index: usize = 0;
            var lists: [ComponentTypes.len]*std.ArrayList(u32) = undefined;

            inline for (ComponentTypes, 0..) |T, i| {
                const set = componentFieldPtr(&ecs.components, T);
                lists[i] = &set.entity_indices;
                const size = set.entity_indices.items.len;
                if (size < smallest_size) {
                    smallest_size = size;
                    best_index = i;
                }
            }

            return Self{
                .ecs = ecs,
                .candidate_component_lists = lists,
                .primary_index = best_index,
                .index = 0,
            };
        }

        pub fn next(self: *Self) ?QueryItem(ComponentTypes) {
            const primary_list = self.candidate_component_lists[self.primary_index];
            while (self.index < primary_list.items.len) {
                const entity_index = primary_list.items[self.index];
                self.index += 1;

                var all_present = true;
                inline for (ComponentTypes) |T| {
                    const set = componentFieldPtr(&self.ecs.components, T);
                    if (!set.hasComponent(entity_index)) {
                        all_present = false;
                        break;
                    }
                }
                if (all_present) {
                    const generation = self.ecs.entity_id_pool.getGeneration(entity_index);
                    const entity_id = EntityId{ .index = entity_index, .generation = generation };
                    return QueryItem(ComponentTypes).init(self.ecs, entity_id);
                    // return QueryItem(ComponentTypes).init(self.ecs, entity_index);
                }
            }
            return null;
        }
    };
}

pub fn QueryItem(_: anytype) type {
    return struct {
        ecs: *ECS,
        entity_id: EntityId,

        fn init(ecs: *ECS, entity_id: EntityId) @This() {
            return .{ .ecs = ecs, .entity_id = entity_id };
        }

        pub fn get(self: @This(), comptime T: type) ?*T {
            return self.ecs.getComponent(self.entity_id, T);
        }
    };
}

pub const ECS = struct {
    allocator: std.mem.Allocator,
    components: ComponentState,
    entity_id_pool: EntityIdPool,
    operation_queue: std.ArrayList(Operation),
    query_active: bool,
    /// Tracks entity indices pending deletion
    entity_index_morgue: std.DynamicBitSet,

    pub fn init(allocator: std.mem.Allocator) ECS {
        var ecs: ECS = undefined;
        inline for (ComponentRegistry) |entry| {
            const set: SparseComponentSet(entry.component_type) = .init(allocator);
            @field(&ecs.components, entry.field_name) = set;
        }

        ecs.allocator = allocator;
        ecs.entity_id_pool = EntityIdPool.init(allocator);
        ecs.operation_queue = std.ArrayList(Operation).empty;
        ecs.entity_index_morgue = std.DynamicBitSet.initEmpty(
            allocator,
            256,
        ) catch {
            @panic("OOM");
        };
        ecs.query_active = false;

        return ecs;
    }

    pub fn deinit(self: *ECS) void {
        inline for (ComponentRegistry) |C| {
            @field(&self.components, C.field_name).deinit();
        }

        self.operation_queue.deinit(self.allocator);
        self.entity_id_pool.deinit();
        self.entity_index_morgue.deinit();
    }

    pub fn assignEntityId(self: *ECS) EntityId {
        const id: EntityId = self.entity_id_pool.assign();

        if (id.index >= self.entity_index_morgue.capacity()) {
            self.entity_index_morgue.resize(id.index + 1, false) catch {
                @panic("OOM");
            };
        }

        return id;
    }

    pub fn addComponent(self: *ECS, entity_id: EntityId, value: anytype) void {
        if (!self.entity_id_pool.isAlive(entity_id)) {
            return;
        }

        const ComponentType = @TypeOf(value);

        if (!self.query_active) {
            const set = componentFieldPtr(&self.components, ComponentType);
            set.addComponent(entity_id.index, value);
            return;
        }

        const component = lookup_component_type: {
            inline for (ComponentRegistry) |entry| {
                if (ComponentType != entry.component_type) {
                    continue;
                }

                break :lookup_component_type @unionInit(
                    ComponentUnion,
                    entry.field_name,
                    value,
                );
            }

            // ComponentType is guaranteed to be in the registry
            unreachable;
        };

        self.operation_queue.append(self.allocator, Operation{
            .add_component = .{
                .entity_id = entity_id,
                .component = component,
            },
        }) catch {
            @panic("OOM");
        };
    }

    pub fn removeComponent(self: *ECS, entity_id: EntityId, comptime T: type) void {
        if (!self.entity_id_pool.isAlive(entity_id)) {
            return;
        }

        comptime var tag: ?ComponentTag = null;

        inline for (ComponentRegistry, 0..) |entry, i| {
            if (T == entry.component_type) {
                tag = @as(ComponentTag, @enumFromInt(i));
                break;
            }
        }
        const tag_value = tag orelse {
            @compileError("No component of type " ++ @typeName(T) ++ " registered in the ECS");
        };

        if (!self.query_active) {
            componentFieldPtr(&self.components, T).removeComponent(entity_id.index);

            return;
        }

        self.operation_queue.append(self.allocator, Operation{
            .remove_component = .{
                .entity_id = entity_id,
                .tag = tag_value,
            },
        }) catch {
            @panic("OOM");
        };
    }

    pub fn hasComponent(self: *ECS, entity_id: EntityId, comptime T: type) bool {
        if (!self.entity_id_pool.isAlive(entity_id)) {
            return false;
        }

        return componentFieldPtr(&self.components, T).hasComponent(entity_id.index);
    }

    pub fn getComponent(self: *ECS, entity_id: EntityId, comptime T: type) ?*T {
        if (!self.entity_id_pool.isAlive(entity_id)) {
            return null;
        }

        return componentFieldPtr(&self.components, T).getComponent(entity_id.index);
    }

    pub fn deleteEntity(self: *ECS, entity_id: EntityId) void {
        if (self.query_active) {
            self.deleteEntityDeferred(entity_id);
        } else {
            self.deleteEntityImmediate(entity_id);
        }
    }

    pub fn entityIsAlive(self: *ECS, entity_id: EntityId) bool {
        return self.entity_id_pool.isAlive(entity_id);
    }

    pub fn flush(self: *ECS) void {
        for (self.operation_queue.items) |op| {
            switch (op) {
                .add_component => |data| {
                    switch (data.component) {
                        inline else => |value| {
                            const T = @TypeOf(value);
                            const field_ptr = componentFieldPtr(
                                &self.components,
                                T,
                            );
                            field_ptr.addComponent(data.entity_id.index, value);
                        },
                    }
                },
                .remove_component => |data| {
                    if (!self.entity_id_pool.isAlive(data.entity_id)) continue;
                    inline for (ComponentRegistry, 0..) |entry, i| {
                        if (@intFromEnum(data.tag) == i) {
                            const field_ptr = componentFieldPtr(&self.components, entry.component_type);
                            field_ptr.removeComponent(data.entity_id.index);
                            break;
                        }
                    }
                },
                .delete_entity => |data| {
                    inline for (ComponentRegistry) |entry| {
                        if (self.hasComponent(data.entity_id, entry.component_type)) {
                            const field_ptr = componentFieldPtr(
                                &self.components,
                                entry.component_type,
                            );
                            field_ptr.removeComponent(data.entity_id.index);
                        }
                    }
                    self.entity_id_pool.free(data.entity_id);
                },
            }
        }
        self.operation_queue.clearRetainingCapacity();
    }

    pub fn beginQuery(self: *ECS) void {
        self.query_active = true;
    }

    pub fn endQuery(self: *ECS) void {
        self.query_active = false;
        self.flush();
    }

    pub fn query(self: *ECS, comptime queried_components: anytype) Query(queried_components) {
        return Query(queried_components).init(self);
    }

    fn deleteEntityDeferred(self: *ECS, entity_id: EntityId) void {
        const exceeds_morge_capacity: bool = entity_id.index >= self.entity_index_morgue.capacity();
        if (exceeds_morge_capacity) {
            self.entity_index_morgue.resize(entity_id.index + 1, false) catch {
                @panic("OOM");
            };
        }

        const already_in_morgue: bool = self.entity_index_morgue.isSet(entity_id.index);
        if (already_in_morgue) {
            return;
        }

        const operation: Operation = .{
            .delete_entity = .{ .entity_id = entity_id },
        };
        self.operation_queue.append(self.allocator, operation) catch {
            @panic("OOM");
        };
        self.entity_index_morgue.set(entity_id.index);
    }

    fn deleteEntityImmediate(self: *ECS, entity_id: EntityId) void {
        inline for (ComponentRegistry) |entry| {
            if (self.hasComponent(entity_id, entry.component_type)) {
                componentFieldPtr(&self.components, entry.component_type).removeComponent(entity_id.index);
            }
        }
        self.entity_id_pool.free(entity_id);
    }
};

fn componentFieldPtr(comps: *ComponentState, comptime T: type) *SparseComponentSet(T) {
    inline for (ComponentRegistry) |entry| {
        if (T == entry.component_type) {
            return &@field(comps, entry.field_name);
        }
    }
    @compileError("No component of type " ++ @typeName(T) ++ " registered in the ECS");
}
