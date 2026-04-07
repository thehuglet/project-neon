const std = @import("std");

const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;

pub const OnDeath = struct {
    pub const Data = union(enum) {
        explosion: struct {
            damage: f32,
            radius: f32,
            collision_mask: u32,
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
