const std = @import("std");

const component = @import("component.zig");
const SparseSet = @import("sparse_set.zig").SparseSet;

pub const ComponentState = struct {
    position: SparseSet(component.Position),
    rotation: SparseSet(component.Rotation),
    velocity: SparseSet(component.Velocity),
};

pub const EntityIdPool = struct {
    next_id: u32,
    recycled: std.ArrayList(u32),

    pub fn init() !EntityIdPool {
        return EntityIdPool{
            .next_id = 0,
            .recycled = .empty(),
        };
    }

    pub fn assign(self: *EntityIdPool) u32 {
        if (self.recycled.items.len > 0) {
            return self.recycled.pop();
        } else {
            const id = self.next_id;
            self.next_id += 1;
            return id;
        }
    }

    pub fn destroy(self: *EntityIdPool, entity_id: u32) void {
        _ = self.recycled.append(entity_id);
    }
};

pub const ECS = struct {
    components: ComponentState,
    entity_id_pool: EntityIdPool,

    pub fn init(allocator: *std.mem.Allocator) !ECS {
        return ECS{
            .components = ComponentState{
                .position = SparseSet(component.Position).init(),
                .rotation = SparseSet(component.Rotation).init(),
                .velocity = SparseSet(component.Velocity).init(),
            },
            .entity_id_pool = try EntityIdPool.init(allocator),
        };
    }
};
