const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn playerInputs(ecs: *ECS) void {
    var query = ecs.query(.{
        c.PlayerInput,
    });
    while (query.next()) |item| {
        const player_input: *c.PlayerInput = item.get(c.PlayerInput).?;

        player_input.move_up = rl.isKeyDown(rl.KeyboardKey.w);
        player_input.move_down = rl.isKeyDown(rl.KeyboardKey.s);
        player_input.move_left = rl.isKeyDown(rl.KeyboardKey.a);
        player_input.move_right = rl.isKeyDown(rl.KeyboardKey.d);
        player_input.dash = rl.isKeyDown(rl.KeyboardKey.space);
        player_input.use_primary_fire = rl.isMouseButtonDown(rl.MouseButton.left);
        player_input.use_secondary_fire = rl.isMouseButtonDown(rl.MouseButton.right);
    }
}
