const std = @import("std");

const rl = @import("raylib");

const math = @import("math");

pub const Motion = struct {
    mass: f32 = 10.0,
    friction: f32 = 10.0,
    velocity: rl.Vector2 = math.VECTOR2_ZERO,
};
