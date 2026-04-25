const Context = @import("context").Context;

const rl = @import("raylib");
const c = @import("component");

pub fn cleanupDeadEntities(ctx: *Context) void {
    var query = ctx.ecs.query(.{
        c.Dead,
    });
    while (query.next()) |item| {
        ctx.ecs.deleteEntity(item.entity_id);
    }
}
