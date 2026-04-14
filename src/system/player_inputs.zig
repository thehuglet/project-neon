const Context = @import("context").Context;

const rl = @import("raylib");

pub fn playerInputs(ctx: *Context) void {
    ctx.player_input_state = .{
        .move_up = rl.isKeyDown(rl.KeyboardKey.w),
        .move_down = rl.isKeyDown(rl.KeyboardKey.s),
        .move_left = rl.isKeyDown(rl.KeyboardKey.a),
        .move_right = rl.isKeyDown(rl.KeyboardKey.d),
        .dash = rl.isKeyPressed(rl.KeyboardKey.space),
        .use_primary_fire = rl.isMouseButtonDown(rl.MouseButton.left),
        .use_secondary_fire = rl.isMouseButtonDown(rl.MouseButton.right),
    };
}
