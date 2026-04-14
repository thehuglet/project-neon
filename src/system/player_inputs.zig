const Context = @import("context").Context;

const rl = @import("raylib");
const c = @import("component");

pub fn playerInputs(ctx: *Context) void {
    var query = ctx.ecs.query(.{
        c.PlayerInput,
    });
    while (query.next()) |item| {
        const player_input: *c.PlayerInput = item.get(c.PlayerInput).?;

        player_input.move_up = rl.isKeyDown(rl.KeyboardKey.w);
        player_input.move_down = rl.isKeyDown(rl.KeyboardKey.s);
        player_input.move_left = rl.isKeyDown(rl.KeyboardKey.a);
        player_input.move_right = rl.isKeyDown(rl.KeyboardKey.d);
        player_input.dash = rl.isKeyPressed(rl.KeyboardKey.space);
        player_input.use_primary_fire = rl.isMouseButtonDown(rl.MouseButton.left);
        player_input.use_secondary_fire = rl.isMouseButtonDown(rl.MouseButton.right);
    }
}
