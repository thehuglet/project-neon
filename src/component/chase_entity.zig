const std = @import("std");

const rl = @import("raylib");

const math = @import("math");

pub const ChaseEntity = struct {
    turn_rate: f32,
    /// Has to be a normalized Vector2
    facing_direction: rl.Vector2 = math.VECTOR2_ZERO,
    accel_cone_angle: f32 = std.math.pi / 4.0,
    /// `[0.0..1.0]` range
    accel_impact_on_turn_rate: f32 = 0.5,
};
