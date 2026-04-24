const rl = @import("raylib");

const Context = @import("context").Context;
const EntityId = @import("ecs").EntityId;
const CollisionLayer = @import("context").CollisionLayer;

const c = @import("component");
const a = @import("asset");

const weapon = @import("weapon");
const math = @import("math");

pub fn spawn(
    ctx: *Context,
    pos: rl.Vector2,
    owner: EntityId,
    damage: f32,
    radius: f32,
    collision_mask: CollisionLayer,
) EntityId {
    const entity_id = ctx.ecs.assignEntityId();

    const lifetime_sec = 0.5;

    ctx.ecs.addComponent(entity_id, c.Owner{
        .entity_id = owner,
    });
    ctx.ecs.addComponent(entity_id, c.Transform{
        .pos = pos,
        .rotation_rad = 0.0,
        .scale = 1.0,
    });
    ctx.ecs.addComponent(entity_id, c.Hitbox{
        .radius = radius,
        .mask = collision_mask,
        .damage = damage,
    });
    ctx.ecs.addComponent(entity_id, c.OneTickHitbox{});
    ctx.ecs.addComponent(entity_id, c.Lifetime{
        .initial_sec = lifetime_sec,
        .remaining_sec = lifetime_sec,
    });
    ctx.ecs.addComponent(entity_id, c.RingOverT{
        .radius = radius,
        .t = 0.0,
        .max_radius_at_t = 0.5,
        .fade_in_at_t = 0.0,
        .fade_out_at_t = 0.2,
    });

    return entity_id;
}
