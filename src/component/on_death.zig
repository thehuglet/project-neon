const std = @import("std");

const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const CollisionLayer = @import("context").CollisionLayer;

pub const OnDeath = struct {
    pub const Data = union(enum) {
        explosion: struct {
            damage: f32,
            radius: f32,
            collision_mask: CollisionLayer,
        },
    };

    const Callback = *const fn (
        ecs: *ECS,
        rng: std.Random,
        entity_id: EntityId,
        data: Data,
    ) void;

    callback: Callback,
    data: Data,
};
