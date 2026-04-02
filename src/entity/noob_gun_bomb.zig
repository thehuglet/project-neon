const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const c = @import("component");
const a = @import("asset");

const explosion_entity = @import("explosion.zig");

const weapon = @import("weapon");
const math = @import("math");

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
        .scale = 1.0,
    });
    ecs.addComponent(entity_id, c.Motion{
        .mass = 10.0,
        .friction = 0.0,
        .ignores_drag = true,
        .velocity = math.angleToVec2(facing_angle).scale(1400.0),
    });
    ecs.addComponent(entity_id, c.NeonSprite{
        .atlas = atlas,
        .sprite_index = 0,
        .color = rl.Color.init(255, 100, 0, 255),
        .scale = 1.5,
    });
    ecs.addComponent(entity_id, c.Hitbox{
        .radius = 16.0,
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

pub fn onDeath(ecs: *ECS, spawner: EntityId, data: c.OnDeath.Data) void {
    const spawner_transform: *c.Transform = ecs.getComponent(spawner, c.Transform).?;
    const spawner_owner: *c.Owner = ecs.getComponent(spawner, c.Owner).?;

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
