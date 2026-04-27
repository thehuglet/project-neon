const Context = @import("context").Context;

const rl = @import("raylib");
const helpers = @import("helpers");

pub fn updateCanvasMousePos(ctx: *Context) void {
    const window_mouse_pos = rl.getMousePosition();
    const viewport_size = rl.Vector2{
        .x = @floatFromInt(ctx.viewport_size.width),
        .y = @floatFromInt(ctx.viewport_size.height),
    };

    ctx.mouse_pos = helpers.fromScreenCoords(viewport_size, window_mouse_pos);
}
