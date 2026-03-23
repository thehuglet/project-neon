const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");
const a = @import("asset");

const helpers = @import("helpers");

pub fn spawn(ecs: *ECS, rng: std.Random, assets: *const a.Assets, pos: rl.Vector2) usize {
    const entity_id = ecs.assignEntityId();

    ecs.addComponent(entity_id, c.TargetsPlayer{});
    ecs.addComponent(entity_id, c.Motion{
        .mass = 0.5,
        .friction = 0.0,
    });
    ecs.addComponent(entity_id, c.Movement{
        .max_speed = helpers.randomFloatRange(rng, 1000, 1200.0),
        .accel_time = helpers.randomFloatRange(rng, 1.3, 1.0),
    });

    ecs.addComponent(entity_id, c.Transform{
        .pos = pos,
        .rotation_rad = 0.0,
        .scale = 1.0,
    });
    ecs.addComponent(entity_id, c.NeonSprite{
        .atlas = assets.roto_atlas,
        .sprite_index = 1,
        .color = rl.Color.init(255, 0, 128, 255),
    });
    ecs.addComponent(entity_id, c.SpinCosmetic{
        .speed = 80.0,
    });
    ecs.addComponent(entity_id, c.ChaseEntity{
        .turn_rate = helpers.randomFloatRange(rng, 10.0, 14.0),
        .accel_impact_on_turn_rate = 0.3,
    });
    ecs.addComponent(entity_id, c.Hurtbox{
        .radius = 38.0,
        .layer = c.CollisionLayer.enemy,
    });
    ecs.addComponent(entity_id, c.Hitbox{
        .radius = 25.0,
        .mask = c.CollisionLayer.player,
    });

    return entity_id;
}
