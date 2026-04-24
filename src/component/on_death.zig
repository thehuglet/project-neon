const std = @import("std");

const Context = @import("context").Context;
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
        ctx: *Context,
        entity_id: EntityId,
        data: Data,
    ) void;

    callback: Callback,
    data: Data,
};
