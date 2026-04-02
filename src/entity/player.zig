const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const c = @import("component");
const a = @import("asset");

const weapon = @import("weapon");

pub fn spawn(ecs: *ECS, atlas: a.TextureAtlas, pos: rl.Vector2) EntityId {
    const entity_id = ecs.assignEntityId();

    ecs.addComponent(entity_id, c.Player{});
    ecs.addComponent(entity_id, c.PlayerInput{});
    ecs.addComponent(entity_id, c.WeaponUseIntent{});
    ecs.addComponent(entity_id, c.WeaponSlots{
        .slots = .{
            weapon.createWeapon(.noob_gun),
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
        .atlas = atlas,
        .sprite_index = 8,
        .color = rl.Color.init(100, 200, 255, 255),
    });
    ecs.addComponent(entity_id, c.Hurtbox{
        .radius = 30.0,
        .layer = c.CollisionLayer.player,
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
