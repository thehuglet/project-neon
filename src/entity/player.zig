const EntityId = @import("ecs").EntityId;
const Context = @import("context").Context;

const rl = @import("raylib");
const c = @import("component");
const weapon = @import("weapon");

pub fn spawn(ctx: *Context, pos: rl.Vector2) EntityId {
    const entity_id = ctx.ecs.assignEntityId();
    const ecs = &ctx.ecs;

    ecs.addComponent(entity_id, c.Player{});
    ecs.addComponent(entity_id, c.WeaponUseIntent{});
    ecs.addComponent(entity_id, c.WeaponSlots{
        .slots = .{
            weapon.createWeaponInstance(.noob_gun),
            null,
        },
    });
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
        .atlas = ctx.atlases.get(.cube).?,
        .sprite_index = 8,
        .color = rl.Color.init(100, 200, 255, 255),
    });
    ecs.addComponent(entity_id, c.Hurtbox{
        .radius = 30.0,
        .layer = .{ .player = true },
    });
    ecs.addComponent(entity_id, c.HealthLives{
        .max_lives = 3,
        .lives = 3,
    });
    ecs.addComponent(entity_id, c.Lumen{
        .max_amount = 100.0,
        .amount = 25.0,
    });

    return entity_id;
}
