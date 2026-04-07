const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const c = @import("component");
const a = @import("asset");

const explosion_entity = @import("explosion.zig");

const weapon = @import("weapon");
const math = @import("math");
const helpers = @import("helpers");

pub fn spawn(
    ecs: *ECS,
    owner: EntityId,
    stats: weapon.WeaponPartStats,
    atlas: a.TextureAtlas,
    pos: rl.Vector2,
    facing_angle: f32,
) EntityId {
    if (stats.projectile != .explosion) {
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
        .scale = 2.5,
    });
    ecs.addComponent(entity_id, c.Motion{
        .mass = 10.0,
        .friction = 0.0,
        .ignores_drag = true,
        .velocity = math.angleToVec2(facing_angle).scale(1000.0),
    });
    ecs.addComponent(entity_id, c.NeonSprite{
        .atlas = atlas,
        .sprite_index = 0,
        .color = rl.Color.init(255, 100, 0, 255),
        .scale = 1.0,
    });
    ecs.addComponent(entity_id, c.Hitbox{
        .radius = 8.0,
        .mask = c.CollisionLayer.enemy,
        .damage = stats.projectile.explosion.damage,
    });
    ecs.addComponent(entity_id, c.SpinCosmetic{
        .clockwise = false,
        .speed = 60.0,
    });
    ecs.addComponent(entity_id, c.Owner{
        .entity_id = owner,
    });

    ecs.addComponent(entity_id, c.OnDeath{
        .callback = &onDeath,
        .data = c.OnDeath.Data{
            .explosion = .{
                .damage = stats.projectile.explosion.damage,
                .radius = stats.projectile.explosion.radius,
                .collision_mask = c.CollisionLayer.enemy,
            },
        },
    });

    return entity_id;
}

fn spawnExplosionParticle(
    ecs: *ECS,
    rng: std.Random,
    neon_sprite: *c.NeonSprite,
    transform: *c.Transform,
) void {
    const entity_id: EntityId = ecs.assignEntityId();

    const lifetime_sec: f32 = 1.0;
    const direction: rl.Vector2 = math.angleToVec2(helpers.randomFloatRange(rng, 0.0, std.math.pi * 2.0));
    const force_magnitude: f32 = helpers.randomFloatRange(rng, 20.0, 1100.0);

    const final_velocity = direction.scale(force_magnitude);

    var motion = c.Motion{
        .mass = 10.0,
        .friction = 1.0,
    };

    motion.velocity = final_velocity;

    ecs.addComponent(entity_id, c.DashTrailGhost{
        .lifetime_sec = lifetime_sec,
        .remaining_lifetime_sec = lifetime_sec,
        .hue_shift_over_lifetime = 2.0,
        .scale_over_lifetime = 0.0,
    });
    ecs.addComponent(entity_id, motion);
    ecs.addComponent(entity_id, c.Transform{
        .pos = transform.pos,
        .rotation_rad = helpers.randomFloatRange(rng, 0.0, std.math.pi * 2.0),
        .scale = transform.scale,
    });
    ecs.addComponent(entity_id, c.NeonSprite{
        .atlas = neon_sprite.atlas,
        .sprite_index = neon_sprite.sprite_index,
        .color = neon_sprite.color.alpha(0.35),
        .rotation_rad = helpers.randomFloatRange(rng, 0.0, std.math.pi * 2.0),
        .scale = neon_sprite.scale * 0.5,
        .origin = neon_sprite.origin,
        .tint_base = neon_sprite.tint_base,
    });
}

pub fn onDeath(ecs: *ECS, rng: std.Random, spawner: EntityId, data: c.OnDeath.Data) void {
    const spawner_transform: *c.Transform = ecs.getComponent(spawner, c.Transform).?;
    const spawner_owner: *c.Owner = ecs.getComponent(spawner, c.Owner).?;
    const spawner_neon_sprite: *c.NeonSprite = ecs.getComponent(spawner, c.NeonSprite).?;

    switch (data) {
        .explosion => |explosion| {
            _ = explosion_entity.spawn(
                ecs,
                spawner_transform.pos,
                spawner_owner.entity_id,
                explosion.damage,
                explosion.radius,
                explosion.collision_mask,
            );

            for (0..50) |_| {
                spawnExplosionParticle(ecs, rng, spawner_neon_sprite, spawner_transform);
            }
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
