const Context = @import("context").Context;
const rl = @import("raylib");

const c = @import("component");

pub fn spinCosmeticAccelScaled(ctx: *Context) void {
    const dt: f32 = rl.getFrameTime();

    var query = ctx.ecs.query(.{
        c.SpinCosmeticAccelScaled,
        c.NeonSprite,
        c.Motion,
        c.Movement,
    });
    while (query.next()) |item| {
        const spin: *c.SpinCosmeticAccelScaled = item.get(c.SpinCosmeticAccelScaled).?;
        const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;
        const motion: *c.Motion = item.get(c.Motion).?;
        const movement: *c.Movement = item.get(c.Movement).?;

        const spin_direction: f32 = if (spin.clockwise) 1.0 else -1.0;

        const motion_speed_factor = blk: {
            const speed: f32 = motion.velocity.length();
            break :blk if (movement.max_speed > 0)
                @min(speed / movement.max_speed, 1.0)
            else
                0.0;
        };

        neon_sprite.rotation_rad += spin_direction * motion_speed_factor * spin.speed * 0.2 * dt;
    }
}
