const Context = @import("context").Context;

const rl = @import("raylib");
const c = @import("component");

pub fn updateLifetime(ctx: *Context) void {
    const dt: f32 = rl.getFrameTime();

    var query = ctx.ecs.query(.{
        c.Lifetime,
    });
    while (query.next()) |item| {
        const lifetime: *c.Lifetime = item.get(c.Lifetime).?;

        lifetime.remaining_sec = @max(0.0, lifetime.remaining_sec - dt);
    }
}
