const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");
const a = @import("asset");

pub fn spawn(ecs: *ECS, assets: *const a.Assets, pos: rl.Vector2) usize {
    const entity_id = ecs.assignEntityId();

    ecs.addComponent(entity_id, c.Player{});
    ecs.addComponent(entity_id, c.Transform{
        .pos = pos,
        .rotation_rad = 0.0,
        .scale = 1.0,
    });
    ecs.addComponent(entity_id, c.Motion{
        .mass = 10.0,
        .friction = 100.0,
    });
    ecs.addComponent(entity_id, c.Movement{
        .max_speed = 500.0,
        .accel_time = 0.01,
    });
    ecs.addComponent(entity_id, c.NeonSprite{
        .atlas = assets.cube_atlas,
        .sprite_index = 0,
        .color = rl.Color.init(100, 200, 255, 255),
    });
    ecs.addComponent(entity_id, c.SpriteSwitcher{});
    ecs.addComponent(entity_id, c.Hurtbox{
        .radius = 30.0,
        .layer = c.CollisionLayer.player,
    });

    return entity_id;
}
