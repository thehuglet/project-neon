const rl = @import("raylib");
const weapon = @import("weapon");
const math = @import("math");

const Context = @import("context").Context;
const EntityId = @import("ecs").EntityId;
const c = @import("component");
const TextureAtlas = @import("context").TextureAtlas;
const CollisionLayer = @import("context").CollisionLayer;

pub fn spawn(
    ctx: *Context,
    owner: EntityId,
    stats: weapon.WeaponPartStats,
    pos: rl.Vector2,
    facing_angle: f32,
) EntityId {
    if (stats.projectile != .impact) {
        unreachable;
    }

    const entity_id = ctx.ecs.assignEntityId();

    ctx.ecs.addComponent(entity_id, c.ProjectileWeaponsStats{
        .stats = stats,
    });
    ctx.ecs.addComponent(entity_id, c.DespawnsWhenOOB{});
    ctx.ecs.addComponent(entity_id, c.Transform{
        .pos = pos,
        .rotation_rad = facing_angle * math.RAD_TO_DEG,
        .scale = 1.0,
    });
    ctx.ecs.addComponent(entity_id, c.Motion{
        .mass = 10.0,
        .friction = 0.0,
        .ignores_drag = true,
        .velocity = math.angleToVec2(facing_angle).scale(1600.0),
    });
    ctx.ecs.addComponent(entity_id, c.NeonSprite{
        .atlas_id = .projectile,
        .sprite_index = 0,
        .color = rl.Color.init(0, 200, 0, 255),
        .scale = 1.5,
    });
    ctx.ecs.addComponent(entity_id, c.Hitbox{
        .radius = 16.0,
        .mask = .{ .enemy = true },
        .damage = stats.projectile.impact.damage,
    });
    ctx.ecs.addComponent(entity_id, c.SpinCosmetic{
        .clockwise = true,
        .speed = 60.0,
    });
    ctx.ecs.addComponent(entity_id, c.Owner{
        .entity_id = owner,
    });
    ctx.ecs.addComponent(entity_id, c.GeneratesLumen{
        .amount = stats.projectile.impact.lumen_gain,
    });
    ctx.ecs.addComponent(entity_id, c.DeathParticles{
        .count = 5,
        .extra_velocity_factor = 0.1,
        .scale_factor = 0.3,
        .speed_factor = 0.3,
        .texture = .{
            .atlas_id = .projectile,
            .cell_index = 0,
        },
    });

    return entity_id;
}
