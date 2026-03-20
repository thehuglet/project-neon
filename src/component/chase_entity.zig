const std = @import("std");

const rl = @import("raylib");

const math = @import("math");

pub const ChaseEntity = struct {
    entity_id: usize,
    turn_speed: f32,
    /// Has to be a normalized Vector2
    facing_direction: rl.Vector2 = math.VECTOR2_ZERO,
    acceleration_cone_angle: f32 = std.math.pi / 4.0,
};
