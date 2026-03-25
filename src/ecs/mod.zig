const std = @import("std");

const ComponentRegistry = @import("component").Registry;

const EntityIdPool = @import("entity_id_pool.zig").EntityIdPool;
const SparseComponentSet = @import("sparse_component_set.zig").SparseComponentSet;

pub const ECS = struct {
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
                .type = entry.T,
                .alignment = @alignOf(entry.T),
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
            const FieldType = SparseComponentSet(entry.T);
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
        add_component: struct { entity_id: usize, comp: ComponentUnion },
        remove_component: struct { entity_id: usize, tag: ComponentTag },
        delete_entity: struct { entity_id: usize },
    };

    pub fn Query(comptime ComponentTypes: anytype) type {
        return struct {
            const Self = @This();

            ecs: *ECS,
            // primary_set: *SparseComponentSet(ComponentTypes[0]),
            primary_lists: [ComponentTypes.len]*std.ArrayList(usize),
            primary_index: usize,
            index: usize,

            pub fn init(ecs: *ECS) Self {
                var smallest_size: usize = std.math.maxInt(usize);
                var best_index: usize = 0;
                var lists: [ComponentTypes.len]*std.ArrayList(usize) = undefined;

                inline for (ComponentTypes, 0..) |T, i| {
                    const set = getSparseSetPtr(&ecs.components, T);
                    lists[i] = &set.entity_ids;
                    const size = set.entity_ids.items.len;
                    if (size < smallest_size) {
                        smallest_size = size;
                        best_index = i;
                    }
                }

                return Self{
                    .ecs = ecs,
                    .primary_lists = lists,
                    .primary_index = best_index,
                    .index = 0,
                };
            }

            pub fn next(self: *Self) ?QueryItem(ComponentTypes) {
                const primary_list = self.primary_lists[self.primary_index];
                while (self.index < primary_list.items.len) {
                    const entity_id = primary_list.items[self.index];
                    self.index += 1;

                    var all_present = true;
                    inline for (ComponentTypes) |T| {
                        if (!self.ecs.hasComponent(entity_id, T)) {
                            all_present = false;
                            break;
                        }
                    }
                    if (all_present) {
                        return QueryItem(ComponentTypes).init(self.ecs, entity_id);
                    }
                }
                return null;
            }
        };
    }

    pub fn QueryItem(_: anytype) type {
        return struct {
            ecs: *ECS,
            entity_id: usize,

            fn init(ecs: *ECS, entity_id: usize) @This() {
                return .{ .ecs = ecs, .entity_id = entity_id };
            }

            pub fn get(self: @This(), comptime T: type) ?*T {
                return self.ecs.getComponent(self.entity_id, T);
            }
        };
    }

    components: ComponentState,
    entity_id_pool: EntityIdPool,
    operation_queue: std.ArrayList(Operation),
    query_active: bool,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) ECS {
        var ecs: ECS = undefined;
        inline for (ComponentRegistry) |C| {
            @field(&ecs.components, C.field_name) = SparseComponentSet(C.T).init(allocator);
        }
        ecs.entity_id_pool = EntityIdPool.init();
        ecs.operation_queue = .empty;
        ecs.query_active = false;
        ecs.allocator = allocator;
        return ecs;
    }

    pub fn deinit(self: *ECS) void {
        self.operation_queue.deinit(self.allocator);
        inline for (ComponentRegistry) |C| {
            @field(&self.components, C.field_name).deinit();
        }
        self.entity_id_pool.deinit(self.allocator);
    }

    pub fn addComponent(self: *ECS, entity_id: usize, value: anytype) void {
        const T = @TypeOf(value);

        if (self.query_active) {
            const comp = blk: {
                inline for (ComponentRegistry) |entry| {
                    if (T == entry.T) {
                        break :blk @unionInit(ComponentUnion, entry.field_name, value);
                    }
                }
                // T is guaranteed to be in the registry
                unreachable;
            };
            self.operation_queue.append(self.allocator, .{ .add_component = .{ .entity_id = entity_id, .comp = comp } }) catch @panic("Out of memory");
        } else {
            const set = getSparseSetPtr(&self.components, T);
            set.addComponent(entity_id, value);
        }
    }

    pub fn removeComponent(self: *ECS, entity_id: usize, comptime T: type) void {
        comptime var tag: ?ComponentTag = null;
        inline for (ComponentRegistry, 0..) |entry, i| {
            if (T == entry.T) {
                tag = @as(ComponentTag, @enumFromInt(i));
                break;
            }
        }
        const tag_value = tag orelse @compileError("Unsupported component type");

        if (self.query_active) {
            self.operation_queue.append(self.allocator, .{ .remove_component = .{ .entity_id = entity_id, .tag = tag_value } }) catch @panic("Out of memory");
        } else {
            getSparseSetPtr(&self.components, T).removeComponent(entity_id);
        }
    }

    pub fn hasComponent(self: *ECS, entity_id: usize, comptime T: type) bool {
        return getSparseSetPtr(&self.components, T).hasComponent(entity_id);
    }

    pub fn getComponent(self: *ECS, entity_id: usize, comptime T: type) ?*T {
        return getSparseSetPtr(&self.components, T).getComponent(entity_id);
    }

    pub fn assignEntityId(self: *ECS) usize {
        return self.entity_id_pool.assignEntityId();
    }

    pub fn deleteEntity(self: *ECS, entity_id: usize) void {
        if (self.query_active) {
            self.operation_queue.append(self.allocator, .{ .delete_entity = .{ .entity_id = entity_id } }) catch @panic("OOM");
        } else {
            inline for (ComponentRegistry) |entry| {
                if (self.hasComponent(entity_id, entry.T)) {
                    getSparseSetPtr(&self.components, entry.T).removeComponent(entity_id);
                }
            }
            _ = self.entity_id_pool.freeEntityId(self.allocator, entity_id);
        }
    }

    pub fn flush(self: *ECS) void {
        for (self.operation_queue.items) |op| {
            switch (op) {
                .add_component => |a| {
                    switch (a.comp) {
                        inline else => |value| {
                            const T = @TypeOf(value);
                            const set = getSparseSetPtr(&self.components, T);
                            set.addComponent(a.entity_id, value);
                        },
                    }
                },
                .remove_component => |r| {
                    inline for (ComponentRegistry, 0..) |entry, i| {
                        if (@intFromEnum(r.tag) == i) {
                            getSparseSetPtr(&self.components, entry.T).removeComponent(r.entity_id);
                            break;
                        }
                    }
                },
                .delete_entity => |d| {
                    inline for (ComponentRegistry) |entry| {
                        if (self.hasComponent(d.entity_id, entry.T)) {
                            getSparseSetPtr(&self.components, entry.T).removeComponent(d.entity_id);
                        }
                    }
                    self.entity_id_pool.freeEntityId(self.allocator, d.entity_id);
                },
            }
        }
        self.operation_queue.clearRetainingCapacity();
    }

    pub fn query(self: *ECS, comptime queried_components: anytype) Query(queried_components) {
        return Query(queried_components).init(self);
    }

    pub fn beginQuery(self: *ECS) void {
        self.query_active = true;
    }

    pub fn endQuery(self: *ECS) void {
        self.query_active = false;
        self.flush();
    }

    fn getSparseSetPtr(comps: *ComponentState, comptime T: type) *SparseComponentSet(T) {
        inline for (ComponentRegistry) |entry| {
            if (T == entry.T) {
                return &@field(comps, entry.field_name);
            }
        }
        @compileError("No component of type " ++ @typeName(T) ++ " registered in ECS");
    }
};
