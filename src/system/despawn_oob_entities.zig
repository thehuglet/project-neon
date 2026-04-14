const Context = @import("context").Context;

const rl = @import("raylib");
const c = @import("component");

pub fn despawnOOBEntities(ctx: *Context, margin: f32) void {
    const canvas_width_f32: f32 = @floatFromInt(ctx.canvas_size.width);
    const canvas_height_f32: f32 = @floatFromInt(ctx.canvas_size.height);

    var query = ctx.ecs.query(.{
        c.DespawnsWhenOOB,
        c.Transform,
    });
    while (query.next()) |item| {
        const transform: *c.Transform = item.get(c.Transform).?;

        const oob_left: bool = transform.pos.x < 0 - margin;
        const oob_top: bool = transform.pos.y < 0 - margin;
        const oob_right: bool = transform.pos.x > canvas_width_f32 + margin;
        const oob_bottom: bool = transform.pos.y > canvas_height_f32 + margin;

        if (oob_left or oob_top or oob_right or oob_bottom) {
            item.ecs.deleteEntity(item.entity_id);
        }
    }
}
