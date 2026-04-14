const Context = @import("context").Context;
const c = @import("component");

pub fn oneTickHitbox(ctx: *Context) void {
    var query = ctx.ecs.query(.{
        c.OneTickHitbox,
        c.Hitbox,
    });
    while (query.next()) |item| {
        const hitbox: *c.Hitbox = item.get(c.Hitbox).?;

        hitbox.active = false;
        ctx.ecs.removeComponent(item.entity_id, c.OneTickHitbox);
    }
}
