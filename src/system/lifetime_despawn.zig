const Context = @import("context").Context;
const c = @import("component");

pub fn lifetimeDespawn(ctx: *Context) void {
    var query = ctx.ecs.query(.{
        c.Lifetime,
    });
    while (query.next()) |item| {
        const lifetime: *c.Lifetime = item.get(c.Lifetime).?;

        if (lifetime.remaining_sec <= 0.0) {
            ctx.ecs.addComponent(item.entity_id, c.Dead{});
        }
    }
}
