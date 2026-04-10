const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const CollisionLayer = @import("context").CollisionLayer;
const c = @import("component");
const a = @import("asset");

const helpers = @import("helpers");

pub fn spawn(ecs: *ECS, rng: std.Random, atlas: a.TextureAtlas, pos: rl.Vector2) EntityId {
    const entity_id = ecs.assignEntityId();

    ecs.addComponent(entity_id, c.TargetsPlayer{});
    ecs.addComponent(entity_id, c.Motion{
        .mass = 1.0,
        .friction = 0.0,
    });
    ecs.addComponent(entity_id, c.Movement{
        .max_speed = helpers.randomFloatRange(rng, 300.0, 400.0),
        .accel_time = helpers.randomFloatRange(rng, 0.4, 0.6),
    });
    ecs.addComponent(entity_id, c.Transform{
        .pos = pos,
        .rotation_rad = 0.0,
        .scale = 1.0,
    });
    ecs.addComponent(entity_id, c.NeonSprite{
        .atlas = atlas,
        .sprite_index = 0,
        .color = rl.Color.init(255, 0, 60, 255),
    });
    ecs.addComponent(entity_id, c.SpinCosmeticAccelScaled{
        .speed = 40.0,
    });
    ecs.addComponent(entity_id, c.ChaseEntity{
        .turn_rate = helpers.randomFloatRange(rng, 10.0, 14.0),
        .accel_impact_on_turn_rate = 0.5,
    });
    ecs.addComponent(entity_id, c.Hurtbox{
        .radius = 38.0,
        .layer = CollisionLayer.ENEMY,
    });
    ecs.addComponent(entity_id, c.Hitbox{
        .radius = 25.0,
        .mask = CollisionLayer.player,
    });

    return entity_id;
}
