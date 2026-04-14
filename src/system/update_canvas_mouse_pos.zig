const Context = @import("context").Context;

const rl = @import("raylib");
const helpers = @import("helpers");

pub fn updateCanvasMousePos(ctx: *Context) void {
    const window_mouse_pos = rl.getMousePosition();
    const canvas_size = rl.Vector2{
        .x = @floatFromInt(ctx.canvas_size.width),
        .y = @floatFromInt(ctx.canvas_size.height),
    };

    ctx.mouse_pos = helpers.fromScreenCoords(canvas_size, window_mouse_pos);
}
