const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const c = @import("component");
const a = @import("asset");

const weapon = @import("weapon");
const math = @import("math");

pub fn spawn(
    ecs: *ECS,
    pos: rl.Vector2,
    owner: EntityId,
    damage: f32,
    radius: f32,
    collision_mask: u32,
) EntityId {
    const entity_id = ecs.assignEntityId();

    const lifetime_sec = 0.5;

    ecs.addComponent(entity_id, c.Owner{
        .entity_id = owner,
    });
    ecs.addComponent(entity_id, c.Transform{
        .pos = pos,
        .rotation_rad = 0.0,
        .scale = 1.0,
    });
    ecs.addComponent(entity_id, c.Hitbox{
        .radius = radius,
        .mask = collision_mask,
        .damage = damage,
    });
    ecs.addComponent(entity_id, c.OneTickHitbox{});
    ecs.addComponent(entity_id, c.Lifetime{
        .initial_sec = lifetime_sec,
        .remaining_sec = lifetime_sec,
    });
    ecs.addComponent(entity_id, c.RingOverT{
        .radius = radius,
        .t = 0.0,
        .max_radius_at_t = 0.3,
        .fade_in_at_t = 0.2,
        .fade_out_at_t = 0.3,
    });

    return entity_id;
}
