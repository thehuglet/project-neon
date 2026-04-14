const Context = @import("context").Context;

const rl = @import("raylib");
const c = @import("component");
const math = @import("math");

const DRAG: f32 = 0.2;

pub fn motionApplyDragFriction(ctx: *Context) void {
    const dt: f32 = rl.getFrameTime();

    var query = ctx.ecs.query(.{
        c.Motion,
    });

    while (query.next()) |item| {
        const motion: *c.Motion = item.get(c.Motion).?;

        var velocity: rl.Vector2 = motion.velocity;
        const speed: f32 = velocity.length();

        if (speed <= 0.0001) {
            motion.velocity = math.VECTOR2_ZERO;
            continue;
        }

        if (!motion.ignores_drag) {
            const mass_scaled: f32 = motion.mass * 0.005;
            const drag_force: rl.Vector2 = velocity.scale(
                -DRAG * mass_scaled * speed * dt,
            );
            velocity = velocity.add(drag_force);
        }

        const friction_strength: f32 = motion.friction * 20.0 * dt;
        if (friction_strength >= speed) {
            velocity = math.VECTOR2_ZERO;
        } else {
            const friction_force: rl.Vector2 = velocity.normalize().scale(-friction_strength);
            velocity = velocity.add(friction_force);
        }

        motion.velocity = velocity;
    }
}
