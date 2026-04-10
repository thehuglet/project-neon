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

    const max_hp = 100.0;

    ecs.addComponent(entity_id, c.TargetsPlayer{});
    ecs.addComponent(entity_id, c.Motion{
        .mass = 0.5,
        .friction = 0.0,
    });
    ecs.addComponent(entity_id, c.Movement{
        .max_speed = helpers.randomFloatRange(rng, 1000, 1200.0),
        .accel_time = helpers.randomFloatRange(rng, 1.3, 1.0),
    });
    ecs.addComponent(entity_id, c.Health{
        .max_health = max_hp,
        .health = max_hp,
    });
    ecs.addComponent(entity_id, c.Transform{
        .pos = pos,
        .rotation_rad = 0.0,
        .scale = 1.0,
    });
    ecs.addComponent(entity_id, c.NeonSprite{
        .atlas = atlas,
        .sprite_index = 1,
        .color = rl.Color.init(255, 0, 128, 255),
    });
    ecs.addComponent(entity_id, c.SpinCosmeticAccelScaled{
        .speed = 80.0,
    });
    ecs.addComponent(entity_id, c.ChaseEntity{
        .turn_rate = helpers.randomFloatRange(rng, 10.0, 14.0),
        .accel_impact_on_turn_rate = 0.3,
    });
    ecs.addComponent(entity_id, c.Hurtbox{
        .radius = 38.0,
        .layer = CollisionLayer.enemy,
    });
    ecs.addComponent(entity_id, c.Hitbox{
        .radius = 25.0,
        .mask = CollisionLayer.player,
        .damage = 0.0,
    });

    return entity_id;
}
