const Context = @import("context").Context;

const std = @import("std");
const rl = @import("raylib");
const c = @import("component");
const helpers = @import("helpers");

pub fn drawStarfieldBackground(ctx: *Context) void {
    const game_time: f32 = @floatCast(rl.getTime());
    const shader = ctx.shaders.get(.starfield).?;
    const u_time = helpers.shaderUniform(shader, "u_time");
    rl.setShaderValue(shader, u_time, &game_time, .float);

    // rl.beginShaderMode(shader);
    rl.drawRectangle(
        0,
        0,
        ctx.canvas_size.width,
        ctx.canvas_size.height,
        rl.Color.black,
    );
    // rl.endShaderMode();
}
