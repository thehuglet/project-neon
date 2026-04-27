const rl = @import("raylib");

const Context = @import("context").Context;
const EntityId = @import("ecs").EntityId;
const c = @import("component");
const TextureAtlas = @import("context").TextureAtlas;
const CollisionLayer = @import("context").CollisionLayer;

const weapon = @import("weapon");
const math = @import("math");

pub fn spawn(
    ctx: *Context,
    owner: EntityId,
    stats: weapon.WeaponPartStats,
    atlas: TextureAtlas,
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
        .atlas = atlas,
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
    // ctx.ecs.addComponent(entity_id, c.OnDeath{
    //     .callback = &onDeath,
    //     .data = c.OnDeath.Data{
    //         .explosion = .{
    //             .damage = stats.projectile.explosion.damage,
    //             .radius = stats.projectile.explosion.radius,
    //             .collision_mask = .{ .enemy = true },
    //         },
    //     },
    // });

    return entity_id;
}

// fn onDeath(ctx: *Context, entity_id: EntityId, data: c.OnDeath.Data) void {
//     switch (data) {
//         .explosion => |explosion| {},
//         else => {},
//     }
// }
