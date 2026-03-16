const std = @import("std");

const components = @import("components.zig");
const EntityIdPool = @import("entity_id.zig").EntityIdPool;
const SparseSet = @import("sparse_set.zig").SparseSet;

pub const ComponentState = struct {
    position: SparseSet(components.Position),
    rotation: SparseSet(components.Rotation),
    velocity: SparseSet(components.Velocity),
};

pub const ECS = struct {
    components: ComponentState,
    entity_id_pool: EntityIdPool,

    pub fn init(allocator: std.mem.Allocator) ECS {
        return ECS{
            .components = ComponentState{
                .position = SparseSet(components.Position).init(allocator),
                .rotation = SparseSet(components.Rotation).init(allocator),
                .velocity = SparseSet(components.Velocity).init(allocator),
            },
            .entity_id_pool = EntityIdPool.init(),
        };
    }

    pub fn addComponent(self: *ECS, entity_id: u32, value: anytype) void {
        const c = &self.components;
        switch (@TypeOf(value)) {
            components.Position => c.position.addComponent(entity_id, value),
            components.Velocity => c.velocity.addComponent(entity_id, value),
            components.Rotation => c.rotation.addComponent(entity_id, value),
            else => @compileError("Unsupported component type"),
        }
    }
};
