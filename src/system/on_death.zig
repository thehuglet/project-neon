const Context = @import("context").Context;

const std = @import("std");
const rl = @import("raylib");
const c = @import("component");

pub fn onDeath(ctx: *Context) void {
    var query = ctx.ecs.query(.{
        c.OnDeath,
        c.Dead,
    });
    while (query.next()) |item| {
        const on_death: *c.OnDeath = item.get(c.OnDeath).?;

        on_death.callback(ctx, item.entity_id, on_death.data);
    }
}
