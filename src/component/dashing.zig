const rl = @import("raylib");

pub const Dashing = struct {
    speed: f32,
    remaining_distance: f32,
    direction: rl.Vector2,
    trail: union(enum) {
        none,
        ghost_spawner: struct {
            spawn_rate: f32,
            spawn_cooldown: f32 = 0.0,
        },
    },
};
