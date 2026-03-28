const rl = @import("raylib");

pub const Dashing = struct {
    const Trail = union(enum) {
        none,
        ghost_spawner: struct {
            spawn_rate: f32,

            // runtime values
            spawn_cooldown: f32 = 0.0,
        },
    };

    speed: f32,
    remaining_distance: f32,
    direction: rl.Vector2,
    trail: Trail,
};
