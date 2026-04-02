const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;

const e = @import("entity");
const c = @import("component");
const a = @import("asset");

const math = @import("math");
const helpers = @import("helpers");

pub const WeaponId = enum {
    noob_gun,
};

pub const TriggerMode = enum {
    semi,
    auto,
};

const Projectile = union(enum) {
    impact: struct {
        damage: f32,
        lumen_gain: f32 = 0.0,
        piercing: u32 = 1,
    },
    explosion: struct {
        damage: f32,
        radius: f32,
        lumen_gain: f32 = 0.0,
        // falloff: f32,
        // /// [0.0..1.0]
        // falloff_start: f32 = 0.8,
    },
};

pub const WeaponPartStats = struct {
    trigger_mode: TriggerMode,
    fire_rate: f32,
    projectile: Projectile,
    lumen_cost: f32 = 0.0,
};

pub const WeaponStats = struct {
    primary: WeaponPartStats,
    secondary: WeaponPartStats,
};

pub const WeaponInstance = struct {
    id: WeaponId,

    // Runtime trackers
    remaining_primary_cooldown: f32 = 0.0,
    remaining_secondary_cooldown: f32 = 0.0,
};

pub const STATS = std.EnumMap(WeaponId, WeaponStats).init(.{
    .noob_gun = WeaponStats{
        .primary = WeaponPartStats{
            .trigger_mode = .auto,
            .fire_rate = 4.0,
            .projectile = Projectile{
                .impact = .{
                    .damage = 40.0,
                    .lumen_gain = 2.0,
                },
            },
        },
        .secondary = WeaponPartStats{
            .trigger_mode = .semi,
            .fire_rate = 4.0,
            .lumen_cost = 0.0,
            .projectile = Projectile{
                .explosion = .{
                    .damage = 100.0,
                    .lumen_gain = 0.0,
                    .radius = 120.0,
                },
            },
        },
    },
});

pub fn createWeapon(weapon_id: WeaponId) WeaponInstance {
    return WeaponInstance{
        .id = weapon_id,
    };
}

pub fn usePrimary(
    ecs: *ECS,
    rng: std.Random,
    weapon_id: WeaponId,
    projectile_atlas: a.TextureAtlas,
    entity: EntityId,
    entity_transform: *c.Transform,
    mouse_pos: rl.Vector2,
) void {
    _ = rng;
    const weapon_part_stats = STATS.get(weapon_id).?.primary;

    const maybe_lumen = ecs.getComponent(entity, c.Lumen);
    if (maybe_lumen) |lumen| {
        if (weapon_part_stats.lumen_cost >= lumen.amount) {
            // Not enough lumen
            return;
        }
        lumen.amount = std.math.clamp(
            lumen.amount - weapon_part_stats.lumen_cost,
            0.0,
            lumen.max_amount,
        );
    }

    switch (weapon_id) {
        .noob_gun => {
            _ = e.noob_gun_bullet.spawn(
                ecs,
                entity,
                weapon_part_stats,
                projectile_atlas,
                entity_transform.pos,
                math.vec2ToAngle(
                    math.direction(entity_transform.pos, mouse_pos),
                ),
            );
        },
    }
}

pub fn useSecondary(
    ecs: *ECS,
    rng: std.Random,
    weapon_id: WeaponId,
    projectile_atlas: a.TextureAtlas,
    entity: EntityId,
    entity_transform: *c.Transform,
    mouse_pos: rl.Vector2,
) void {
    _ = rng;
    const weapon_part_stats = STATS.get(weapon_id).?.secondary;

    const maybe_lumen = ecs.getComponent(entity, c.Lumen);
    if (maybe_lumen) |lumen| {
        if (weapon_part_stats.lumen_cost >= lumen.amount) {
            // Not enough lumen
            return;
        }
        lumen.amount = std.math.clamp(
            lumen.amount - weapon_part_stats.lumen_cost,
            0.0,
            lumen.max_amount,
        );
    }

    switch (weapon_id) {
        .noob_gun => {
            _ = e.noob_gun_bomb.spawn(
                ecs,
                entity,
                weapon_part_stats,
                projectile_atlas,
                entity_transform.pos,
                math.vec2ToAngle(
                    math.direction(entity_transform.pos, mouse_pos),
                ),
            );
        },
    }
}
