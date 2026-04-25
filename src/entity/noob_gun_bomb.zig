const std = @import("std");

const rl = @import("raylib");

const Context = @import("context").Context;
const EntityId = @import("ecs").EntityId;
const c = @import("component");
const TextureAtlas = @import("context").TextureAtlas;
const CollisionLayer = @import("context").CollisionLayer;

const explosion_entity = @import("explosion.zig");

const weapon = @import("weapon");
const math = @import("math");
const helpers = @import("helpers");
const particle = @import("particle");

pub fn spawn(
    ctx: *Context,
    owner: EntityId,
    stats: weapon.WeaponPartStats,
    atlas: TextureAtlas,
    pos: rl.Vector2,
    facing_angle: f32,
) EntityId {
    if (stats.projectile != .explosion) {
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
        .scale = 2.5,
    });
    ctx.ecs.addComponent(entity_id, c.Motion{
        .mass = 10.0,
        .friction = 0.0,
        .ignores_drag = true,
        .velocity = math.angleToVec2(facing_angle).scale(1000.0),
    });
    ctx.ecs.addComponent(entity_id, c.NeonSprite{
        .atlas = atlas,
        .sprite_index = 0,
        .color = rl.Color.init(255, 100, 0, 255),
        .scale = 1.0,
    });
    ctx.ecs.addComponent(entity_id, c.Hitbox{
        .radius = 8.0,
        .mask = .{ .enemy = true },
        .damage = stats.projectile.explosion.damage,
    });
    ctx.ecs.addComponent(entity_id, c.SpinCosmetic{
        .clockwise = false,
        .speed = 60.0,
    });
    ctx.ecs.addComponent(entity_id, c.Owner{
        .entity_id = owner,
    });

    ctx.ecs.addComponent(entity_id, c.OnDeath{
        .callback = &onDeath,
        .data = c.OnDeath.Data{
            .explosion = .{
                .damage = stats.projectile.explosion.damage,
                .radius = stats.projectile.explosion.radius,
                .collision_mask = .{ .enemy = true },
            },
        },
    });

    return entity_id;
}

pub fn onDeath(ctx: *Context, spawner: EntityId, data: c.OnDeath.Data) void {
    const spawner_transform: *c.Transform = ctx.ecs.getComponent(spawner, c.Transform).?;
    const spawner_owner: *c.Owner = ctx.ecs.getComponent(spawner, c.Owner).?;
    // const spawner_neon_sprite: *c.NeonSprite = ctx.ecs.getComponent(spawner, c.NeonSprite).?;

    std.debug.print("spawned\n", .{});

    switch (data) {
        .explosion => |explosion| {
            _ = explosion_entity.spawn(
                ctx,
                spawner_transform.pos,
                spawner_owner.entity_id,
                explosion.damage,
                explosion.radius,
                explosion.collision_mask,
            );

            particle.spawnBurst(
                &ctx.particle_system,
                spawner_transform.pos,
                .{
                    .color = rl.Color.init(255, 100, 40, 255).alpha(0.35),
                    .texture = .{ .atlas_id = .projectile, .cell_index = 0 },
                    .speed = .{ .range = .{ .min = 80.0, .max = 1000.0 } },
                    .scale = .{ .range = .{ .min = 70.0, .max = 100.0 } },
                    .scale_over_t = 0.0,
                    .alpha_over_t = 0.0,
                    .hue_shift_over_t = 1.0,
                    .lifetime_sec = .{ .range = .{ .min = 0.3, .max = 1.0 } },
                },
            );

            // for (0..50) |_| {
            // spawnExplosionParticle(ecs, rng, spawner_neon_sprite, spawner_transform);
            // }
        },

        // else => {
        //     const tag = std.meta.activeTag(data);
        //     std.log.warn(
        //         "Received unsupported OnDeath.Data variant '{}'",
        //         .{@tagName(tag)},
        //     );
        // },
    }
}
