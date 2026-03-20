const std = @import("std");

const rl = @import("raylib");

pub const VECTOR2_ZERO = rl.Vector2{ .x = 0.0, .y = 0.0 };

pub const RAD_TO_DEG: f32 = 57.2957795;
pub const DEG_TO_RAD: f32 = 0.0174532925;

/// Returns an angle in radians
pub fn vec2ToAngle(vec: rl.Vector2) f32 {
    return std.math.atan2(vec.y, vec.x);
}

/// Angle is expected to be in radians
pub fn angleToVec2(angle: f32) rl.Vector2 {
    return .{ .x = @cos(angle), .y = @sin(angle) };
}

pub fn lerpAngle(a: f32, b: f32, t: f32) f32 {
    const diff = wrapAnglePi(b - a);
    return a + diff * t;
}

pub fn direction(from: rl.Vector2, to: rl.Vector2) rl.Vector2 {
    return rl.Vector2.subtract(to, from).normalize();
}

pub fn wrapAnglePi(angle: f32) f32 {
    const twoPi: f32 = 2.0 * std.math.pi;
    var a = @rem(angle, twoPi);

    if (a > std.math.pi) {
        a -= twoPi;
    } else if (a < -std.math.pi) {
        a += twoPi;
    }

    return a;
}
