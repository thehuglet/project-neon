const std = @import("std");

const rl = @import("raylib");

const c = @import("component");

pub fn accelerate(motion: *c.Motion, movement: *const c.Movement, direction: rl.Vector2, delta_time: f32) void {
    if (direction.length() == 0.0) return;

    const normalized = direction.normalize();
    const target_velocity = normalized.scale(movement.max_speed);

    const t = delta_time / movement.accel_time;
    const factor = @min(t, 1.0);

    const delta = rl.math.vector2Subtract(target_velocity, motion.velocity);
    const change = delta.scale(factor);

    motion.velocity = rl.math.vector2Add(
        motion.velocity,
        change,
    );

    const speed = motion.velocity.length();
    if (speed > movement.max_speed) {
        motion.velocity =
            motion.velocity.scale(movement.max_speed / speed);
    }
}

pub fn brake(motion: *c.Motion, movement: *const c.Movement, delta_time: f32) void {
    const speed = motion.velocity.length();
    if (speed == 0.0) return;

    const t = delta_time / movement.brake_time;
    const factor = @min(t, 1.0);

    const reduction = motion.velocity.scale(factor);

    motion.velocity = rl.math.vector2Subtract(
        motion.velocity,
        reduction,
    );

    if (motion.velocity.length() < 0.001) {
        motion.velocity = rl.Vector2.zero();
    }
}

pub fn randomFloatRange(random: std.Random, min: f32, max: f32) f32 {
    return min + random.float(f32) * (max - min);
}

/// Retrieves the shader uniform location.
///
/// # PANIC
/// Will panic if the uniform location doesn't exist.
pub fn shaderUniform(shader: rl.Shader, uniform_name: [:0]const u8) i32 {
    const loc = rl.getShaderLocation(shader, uniform_name);
    if (loc == -1) {
        std.debug.panic("Uniform not found: {s}", .{uniform_name});
    }
    return loc;
}

/// Returns the X scale of the window in relation to the native size.
pub fn screenScaleX(native_width: f32) f32 {
    return @as(f32, @floatFromInt(rl.getScreenWidth())) / native_width;
}

/// Returns the Y scale of the window in relation to the native size.
pub fn screenScaleY(native_height: f32) f32 {
    return @as(f32, @floatFromInt(rl.getScreenHeight())) / native_height;
}
