const Context = @import("context").Context;
const rl = @import("raylib");
const c = @import("component");

pub fn updateRingOverTLifetime(ctx: *Context) void {
    var query = ctx.ecs.query(.{
        c.RingOverT,
        c.Lifetime,
    });
    while (query.next()) |item| {
        const ring: *c.RingOverT = item.get(c.RingOverT).?;
        const lifetime: *c.Lifetime = item.get(c.Lifetime).?;

        ring.t = 1.0 - (lifetime.remaining_sec / lifetime.initial_sec);
    }
}
