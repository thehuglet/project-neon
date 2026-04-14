const Context = @import("context").Context;

const rl = @import("raylib");
const c = @import("component");

pub fn applyMotionToTransform(ctx: *Context) void {
    const dt: f32 = rl.getFrameTime();

    var query = ctx.ecs.query(.{
        c.Motion,
        c.Transform,
    });
    while (query.next()) |item| {
        const motion: *c.Motion = item.get(c.Motion).?;
        const transform: *c.Transform = item.get(c.Transform).?;

        transform.pos = transform.pos.add(motion.velocity.scale(dt));
    }
}
