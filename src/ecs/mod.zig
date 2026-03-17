const std = @import("std");

const components = @import("components.zig");
const EntityIdPool = @import("entity.zig").EntityIdPool;
const SparseSet = @import("sparse_set.zig").SparseSet;

pub const ComponentState = struct {
    player: SparseSet(components.Player),
    position: SparseSet(components.Position),
    rotation: SparseSet(components.Rotation),
    velocity: SparseSet(components.Velocity),
};

pub const ECS = struct {
    pub const ComponentList = [_]struct {
        T: type,
        field_name: [:0]const u8,
    }{
        .{ .T = components.Player, .field_name = "player" },
        .{ .T = components.Position, .field_name = "position" },
        .{ .T = components.Rotation, .field_name = "rotation" },
        .{ .T = components.Velocity, .field_name = "velocity" },
    };

    const ComponentUnion = blk: {
        const field_count = ComponentList.len;
        var fields: [field_count]std.builtin.Type.UnionField = undefined;
        for (ComponentList, 0..) |entry, i| {
            fields[i] = .{
                .name = entry.field_name,
                .type = entry.T,
                .alignment = @alignOf(entry.T),
            };
        }
        break :blk @Type(.{
            .@"union" = .{
                .layout = .auto,
                .tag_type = null,
                .fields = fields[0..],
                .decls = &.{},
            },
        });
    };

    const ComponentTag = blk: {
        var enum_fields: [ComponentList.len]std.builtin.Type.EnumField = undefined;
        for (ComponentList, 0..) |entry, i| {
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

    const Operation = union(enum) {
        add: struct { entity: usize, comp: ComponentUnion },
        remove: struct { entity: usize, tag: ComponentTag },
    };

    pub fn Query(comptime ComponentTypes: anytype) type {
        return struct {
            const Self = @This();

            ecs: *ECS,
            primary_set: *SparseSet(ComponentTypes[0]),
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
            entity: usize,

            fn init(ecs: *ECS, entity: usize) @This() {
                return .{ .ecs = ecs, .entity = entity };
            }

            pub fn get(self: @This(), comptime T: type) ?*T {
                return self.ecs.getComponent(self.entity, T);
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
        inline for (ComponentList) |C| {
            @field(&ecs.components, C.field_name) = SparseSet(C.T).init(allocator);
        }
        ecs.entity_id_pool = EntityIdPool.init();
        ecs.operation_queue = .empty;
        ecs.query_active = false;
        ecs.allocator = allocator;
        return ecs;
    }

    pub fn deinit(ecs: *ECS) void {
        ecs.operation_queue.deinit(ecs.allocator);
        inline for (ComponentList) |C| {
            @field(&ecs.components, C.field_name).deinit();
        }
    }

    pub fn addComponent(ecs: *ECS, entity: usize, value: anytype) void {
        const T = @TypeOf(value);

        comptime var tag: ?ComponentTag = null;
        inline for (ComponentList, 0..) |entry, i| {
            if (T == entry.T) {
                tag = @as(ComponentTag, @enumFromInt(i));
                break;
            }
        }

        if (ecs.query_active) {
            var comp: ComponentUnion = undefined;
            inline for (ComponentList) |entry| {
                if (T == entry.T) {
                    @field(comp, entry.field_name) = value;
                    break;
                }
            }
            ecs.operation_queue.append(ecs.allocator, .{ .add = .{ .entity = entity, .comp = comp } }) catch @panic("Out of memory");
        } else {
            getSparseSetPtr(&ecs.components, T).addComponent(entity, value);
        }
    }

    pub fn removeComponent(ecs: *ECS, entity: usize, comptime T: type) void {
        comptime var tag: ?ComponentTag = null;
        inline for (ComponentList, 0..) |entry, i| {
            if (T == entry.T) {
                tag = @as(ComponentTag, @enumFromInt(i));
                break;
            }
        }
        const tag_value = tag orelse @compileError("Unsupported component type");

        if (ecs.query_active) {
            ecs.operation_queue.append(ecs.allocator, .{ .remove = .{ .entity = entity, .tag = tag_value } }) catch @panic("Out of memory");
        } else {
            getSparseSetPtr(&ecs.components, T).removeComponent(entity);
        }
    }

    pub fn hasComponent(ecs: *ECS, entity: usize, comptime T: type) bool {
        return getSparseSetPtr(&ecs.components, T).hasComponent(entity);
    }

    pub fn getComponent(ecs: *ECS, entity: usize, comptime T: type) ?*T {
        return getSparseSetPtr(&ecs.components, T).getComponent(entity);
    }

    fn getSparseSetPtr(comps: *ComponentState, comptime T: type) *SparseSet(T) {
        inline for (ComponentList) |entry| {
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
                    inline for (ComponentList) |entry| {
                        if (@hasField(@TypeOf(a.comp), entry.field_name)) {
                            const value = @field(a.comp, entry.field_name);
                            getSparseSetPtr(&ecs.components, entry.T).addComponent(a.entity, value);
                            break;
                        }
                    }
                },
                .remove => |r| {
                    inline for (ComponentList, 0..) |entry, i| {
                        if (@intFromEnum(r.tag) == i) {
                            getSparseSetPtr(&ecs.components, entry.T).removeComponent(r.entity);
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
