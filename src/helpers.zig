const PlayerInputState = @import("context").PlayerInputState;

const std = @import("std");
const rl = @import("raylib");
const c = @import("component");

pub fn motion_accelerate(motion: *c.Motion, movement: *const c.Movement, direction: rl.Vector2, delta_time: f32) void {
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

pub fn motion_brake(motion: *c.Motion, movement: *const c.Movement, delta_time: f32) void {
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

pub fn toScreenCoords(from_size: rl.Vector2, pos: rl.Vector2) rl.Vector2 {
    const screen_w = @as(f32, @floatFromInt(rl.getScreenWidth()));
    const screen_h = @as(f32, @floatFromInt(rl.getScreenHeight()));
    const canvas_w = from_size.x;
    const canvas_h = from_size.y;
    const scale = rl.Vector2{
        .x = screen_w / canvas_w,
        .y = screen_h / canvas_h,
    };
    return rl.Vector2{
        .x = pos.x * scale.x,
        .y = pos.y * scale.y,
    };
}

pub fn fromScreenCoords(to_size: rl.Vector2, pos: rl.Vector2) rl.Vector2 {
    const screen_w = @as(f32, @floatFromInt(rl.getScreenWidth()));
    const screen_h = @as(f32, @floatFromInt(rl.getScreenHeight()));
    const canvas_w = to_size.x;
    const canvas_h = to_size.y;
    const scale = rl.Vector2{
        .x = canvas_w / screen_w,
        .y = canvas_h / screen_h,
    };
    return rl.Vector2{
        .x = pos.x * scale.x,
        .y = pos.y * scale.y,
    };
}

pub fn playerInputDirection(inputs: *const PlayerInputState) rl.Vector2 {
    var input_dir = rl.Vector2.zero();

    if (inputs.move_up) input_dir.y -= 1;
    if (inputs.move_down) input_dir.y += 1;
    if (inputs.move_left) input_dir.x -= 1;
    if (inputs.move_right) input_dir.x += 1;

    if (input_dir.length() == 0.0) {
        return rl.Vector2.zero();
    }
    return rl.Vector2.normalize(input_dir);
}
