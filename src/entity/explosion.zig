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
        .remaining_sec = 0.15,
    });

    return entity_id;
}
