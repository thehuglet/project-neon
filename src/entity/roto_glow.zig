const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");
const a = @import("asset");

pub fn spawn(ecs: *ECS, assets: *const a.Assets, pos: rl.Vector2) usize {
    const entity_id = ecs.assignEntityId();

    ecs.addComponent(entity_id, c.Transform{
        .pos = pos,
        .rotation_rad = 0.0,
        .scale = 1.0,
    });
    ecs.addComponent(entity_id, c.NeonSprite.init(
        assets.roto_atlas,
        0,
        rl.Color.red,
        c.NeonSprite.Options{},
    ));
    ecs.addComponent(entity_id, c.SpinCosmetic{
        .speed = 30.0,
    });
    ecs.addComponent(entity_id, c.MovementSpeed{
        .base = 400.0,
    });
    ecs.addComponent(entity_id, c.DynamicMovementSpeed{
        .current_speed_scale = 0.3,
        .min_speed_scale = 0.1,
        .max_speed_scale = 1.0,
        .acceleration_rate = 1.0,
        .deceleration_rate = 1.0,
    });

    return entity_id;
}
