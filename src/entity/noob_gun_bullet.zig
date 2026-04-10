const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const c = @import("component");
const TextureAtlas = @import("context").TextureAtlas;
const CollisionLayer = @import("context").CollisionLayer;

const weapon = @import("weapon");
const math = @import("math");

pub fn spawn(
    ecs: *ECS,
    owner: EntityId,
    stats: weapon.WeaponPartStats,
    atlas: TextureAtlas,
    pos: rl.Vector2,
    facing_angle: f32,
) EntityId {
    if (stats.projectile != .impact) {
        unreachable;
    }

    const entity_id = ecs.assignEntityId();

    ecs.addComponent(entity_id, c.ProjectileWeaponsStats{
        .stats = stats,
    });
    ecs.addComponent(entity_id, c.DespawnsWhenOOB{});
    ecs.addComponent(entity_id, c.Transform{
        .pos = pos,
        .rotation_rad = facing_angle * math.RAD_TO_DEG,
        .scale = 1.0,
    });
    ecs.addComponent(entity_id, c.Motion{
        .mass = 10.0,
        .friction = 0.0,
        .ignores_drag = true,
        .velocity = math.angleToVec2(facing_angle).scale(1600.0),
    });
    ecs.addComponent(entity_id, c.NeonSprite{
        .atlas = atlas,
        .sprite_index = 0,
        .color = rl.Color.init(0, 200, 0, 255),
        .scale = 1.5,
    });
    ecs.addComponent(entity_id, c.Hitbox{
        .radius = 16.0,
        .mask = .{ .enemy = true },
        .damage = stats.projectile.impact.damage,
    });
    ecs.addComponent(entity_id, c.SpinCosmetic{
        .clockwise = true,
        .speed = 60.0,
    });
    ecs.addComponent(entity_id, c.Owner{
        .entity_id = owner,
    });
    ecs.addComponent(entity_id, c.GeneratesLumen{
        .amount = stats.projectile.impact.lumen_gain,
    });

    return entity_id;
}
