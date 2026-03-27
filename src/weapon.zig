const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const e = @import("entity");
const c = @import("component");
const a = @import("asset");

const math = @import("math");
const helpers = @import("helpers");

pub const TriggerMode = enum {
    semi,
    auto,
};

pub const WeaponId = enum {
    noob_gun,
};

/// This struct should only hold compiletime fields
pub const WeaponStats = struct {
    primary_trigger_mode: TriggerMode,
    secondary_trigger_mode: TriggerMode,

    primary_fire_rate: f32,
    secondary_fire_rate: f32,
};

/// This struct can hold runtime fields
pub const WeaponInstance = struct {
    id: WeaponId,

    // Runtime trackers
    current_primary_cooldown: f32 = 0.0,
    secondary_primary_cooldown: f32 = 0.0,
};

pub const STATS = std.EnumMap(WeaponId, WeaponStats).init(.{
    .noob_gun = WeaponStats{
        .primary_trigger_mode = .auto,
        .primary_fire_rate = 4.0,

        .secondary_trigger_mode = .auto,
        .secondary_fire_rate = 4.0,
    },
});

pub fn createWeapon(weapon_id: WeaponId) WeaponInstance {
    // const stats = STATS.get(weapon_id);
    return WeaponInstance{
        .id = weapon_id,
    };
}

pub fn usePrimary(
    ecs: *ECS,
    rng: std.Random,
    weapon_id: WeaponId,
    projectile_atlas: a.TextureAtlas,
    owner_transform: *c.Transform,
    mouse_pos: rl.Vector2,
) void {
    _ = rng;
    // _ = mouse_pos;

    switch (weapon_id) {
        .noob_gun => {
            // const bullet_count = 5; // how many directions

            // for (0..bullet_count) |i| {
            //     const angle = (2.0 * std.math.pi) * (@as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(bullet_count)));

            //     _ = e.neon_blaster_bullet.spawn(
            //         ecs,
            //         projectile_atlas,
            //         owner_transform.pos,
            //         angle,
            //     );
            // }

            // const angle_offset = helpers.randomFloatRange(rng, -18.0, 18.0) * math.DEG_TO_RAD;
            _ = e.neon_blaster_bullet.spawn(
                ecs,
                projectile_atlas,
                owner_transform.pos,
                math.vec2ToAngle(
                    math.direction(owner_transform.pos, mouse_pos),
                ),
            );
        },
    }
}
