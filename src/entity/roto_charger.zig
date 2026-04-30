const std = @import("std");
const rl = @import("raylib");
const c = @import("component");
const helpers = @import("helpers");

const Context = @import("context").Context;
const EntityId = @import("ecs").EntityId;

pub fn spawn(ctx: *Context, pos: rl.Vector2) EntityId {
    const entity_id = ctx.ecs.assignEntityId();

    const max_hp = 100.0;
    const atlas_sprite_index = 1;

    ctx.ecs.addComponent(entity_id, c.TargetsPlayer{});
    ctx.ecs.addComponent(entity_id, c.Motion{
        .mass = 0.5,
        .friction = 0.0,
    });
    ctx.ecs.addComponent(entity_id, c.Movement{
        .max_speed = helpers.randomFloatRange(ctx.rng, 1000, 1200.0),
        .accel_time = helpers.randomFloatRange(ctx.rng, 1.8, 2.0),
    });
    ctx.ecs.addComponent(entity_id, c.Health{
        .max_health = max_hp,
        .health = max_hp,
    });
    ctx.ecs.addComponent(entity_id, c.Transform{
        .pos = pos,
        .rotation_rad = 0.0,
        .scale = 1.0,
    });
    ctx.ecs.addComponent(entity_id, c.NeonSprite{
        .atlas_id = .roto,
        .sprite_index = atlas_sprite_index,
        .color = rl.Color.init(255, 0, 128, 255),
    });
    ctx.ecs.addComponent(entity_id, c.SpinCosmeticAccelScaled{
        .speed = 80.0,
    });
    ctx.ecs.addComponent(entity_id, c.ChaseEntity{
        .turn_rate = helpers.randomFloatRange(ctx.rng, 10.0, 14.0),
        .accel_impact_on_turn_rate = 0.8,
    });
    ctx.ecs.addComponent(entity_id, c.Hurtbox{
        .radius = 38.0,
        .layer = .{ .enemy = true },
    });
    ctx.ecs.addComponent(entity_id, c.Hitbox{
        .radius = 25.0,
        .mask = .{ .player = true },
        .damage = 0.0,
    });
    ctx.ecs.addComponent(entity_id, c.DeathParticles{
        .count = 10,
        .texture = .{
            .atlas_id = .roto_death,
            .cell_index = atlas_sprite_index,
        },
    });

    return entity_id;
}
