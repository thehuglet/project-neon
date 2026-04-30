const std = @import("std");
const rl = @import("raylib");
const c = @import("component");
const a = @import("asset");
const helpers = @import("helpers");

const Context = @import("context").Context;
const EntityId = @import("ecs").EntityId;

pub fn spawn(ctx: *Context, pos: rl.Vector2) EntityId {
    const entity_id = ctx.ecs.assignEntityId();

    const max_health = 100.0;
    const atlas_sprite_index = 0;

    ctx.ecs.addComponent(entity_id, c.TargetsPlayer{});
    ctx.ecs.addComponent(entity_id, c.Motion{
        .mass = 1.0,
        .friction = 0.0,
    });
    ctx.ecs.addComponent(entity_id, c.Movement{
        .max_speed = helpers.randomFloatRange(ctx.rng, 300.0, 400.0),
        .accel_time = helpers.randomFloatRange(ctx.rng, 0.4, 0.6),
    });
    ctx.ecs.addComponent(entity_id, c.Transform{
        .pos = pos,
        .rotation_rad = 0.0,
        .scale = 1.0,
    });
    ctx.ecs.addComponent(entity_id, c.NeonSprite{
        .atlas_id = .roto,
        .sprite_index = atlas_sprite_index,
        .color = rl.Color.init(255, 0, 60, 255),
    });
    ctx.ecs.addComponent(entity_id, c.SpinCosmeticAccelScaled{
        .speed = 40.0,
    });
    ctx.ecs.addComponent(entity_id, c.Health{
        .max_health = max_health,
        .health = max_health,
    });
    ctx.ecs.addComponent(entity_id, c.ChaseEntity{
        .turn_rate = helpers.randomFloatRange(ctx.rng, 10.0, 14.0),
        .accel_impact_on_turn_rate = 0.5,
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
