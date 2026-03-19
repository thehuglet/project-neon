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
        add: struct { entity_id: usize, comp: ComponentUnion },
        remove: struct { entity_id: usize, tag: ComponentTag },
    };

    pub fn Query(comptime ComponentTypes: anytype) type {
        return struct {
            const Self = @This();

            ecs: *ECS,
            primary_set: *SparseComponentSet(ComponentTypes[0]),
            index: usize,

            pub fn init(ecs: *ECS) Self {
                const primary = getSparseSetPtr(&ecs.components, ComponentTypes[0]);
                return Self{
                    .ecs = ecs,
                    .primary_set = primary,
                    .index = 0,
                };
            }

            pub fn next(self: *Self) ?QueryItem(ComponentTypes) {
                while (self.index < self.primary_set.entity_ids.items.len) {
                    const entity_id = self.primary_set.entity_ids.items[self.index];
                    self.index += 1;

                    var all_present = true;
                    inline for (ComponentTypes) |Comp| {
                        if (!self.ecs.hasComponent(entity_id, Comp)) {
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

    pub fn deinit(ecs: *ECS) void {
        ecs.operation_queue.deinit(ecs.allocator);
        inline for (ComponentRegistry) |C| {
            @field(&ecs.components, C.field_name).deinit();
        }
    }

    pub fn addComponent(ecs: *ECS, entity_id: usize, value: anytype) void {
        const T = @TypeOf(value);

        if (ecs.query_active) {
            const comp = blk: {
                inline for (ComponentRegistry) |entry| {
                    if (T == entry.T) {
                        break :blk @unionInit(ComponentUnion, entry.field_name, value);
                    }
                }
                // T is guaranteed to be in the registry
                unreachable;
            };
            ecs.operation_queue.append(ecs.allocator, .{ .add = .{ .entity_id = entity_id, .comp = comp } }) catch @panic("Out of memory");
        } else {
            getSparseSetPtr(&ecs.components, T).addComponent(entity_id, value);
        }
    }

    pub fn removeComponent(ecs: *ECS, entity_id: usize, comptime T: type) void {
        comptime var tag: ?ComponentTag = null;
        inline for (ComponentRegistry, 0..) |entry, i| {
            if (T == entry.T) {
                tag = @as(ComponentTag, @enumFromInt(i));
                break;
            }
        }
        const tag_value = tag orelse @compileError("Unsupported component type");

        if (ecs.query_active) {
            ecs.operation_queue.append(ecs.allocator, .{ .remove = .{ .entity_id = entity_id, .tag = tag_value } }) catch @panic("Out of memory");
        } else {
            getSparseSetPtr(&ecs.components, T).removeComponent(entity_id);
        }
    }

    pub fn hasComponent(ecs: *ECS, entity_id: usize, comptime T: type) bool {
        return getSparseSetPtr(&ecs.components, T).hasComponent(entity_id);
    }

    pub fn getComponent(ecs: *ECS, entity_id: usize, comptime T: type) ?*T {
        return getSparseSetPtr(&ecs.components, T).getComponent(entity_id);
    }

    fn getSparseSetPtr(comps: *ComponentState, comptime T: type) *SparseComponentSet(T) {
        inline for (ComponentRegistry) |entry| {
            if (T == entry.T) {
                return &@field(comps, entry.field_name);
            }
        }
        @compileError("No component of type " ++ @typeName(T) ++ " registered");
    }

    pub fn assignEntityId(ecs: *ECS) usize {
        return ecs.entity_id_pool.assignEntityId();
    }

    pub fn freeEntityId(ecs: *ECS, entity_id: usize) usize {
        return ecs.entity_id_pool.freeEntityId(entity_id);
    }

    pub fn flush(ecs: *ECS) void {
        for (ecs.operation_queue.items) |op| {
            switch (op) {
                .add => |a| {
                    switch (a.comp) {
                        inline else => |value| {
                            const T = @TypeOf(value);
                            getSparseSetPtr(&ecs.components, T).addComponent(a.entity_id, value);
                        },
                    }
                },
                .remove => |r| {
                    inline for (ComponentRegistry, 0..) |entry, i| {
                        if (@intFromEnum(r.tag) == i) {
                            getSparseSetPtr(&ecs.components, entry.T).removeComponent(r.entity_id);
                            break;
                        }
                    }
                },
            }
        }
        ecs.operation_queue.clearRetainingCapacity();
    }

    pub fn query(ecs: *ECS, comptime queried_components: anytype) Query(queried_components) {
        return Query(queried_components).init(ecs);
    }

    pub fn beginQuery(ecs: *ECS) void {
        ecs.query_active = true;
    }

    pub fn endQuery(ecs: *ECS) void {
        ecs.query_active = false;
        ecs.flush();
    }
};
