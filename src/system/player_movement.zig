const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

const helpers = @import("helpers");

pub fn playerMovement(ecs: *ECS) void {
    const dt: f32 = rl.getFrameTime();

    var query = ecs.query(.{
        c.PlayerInput,
        c.Motion,
        c.Movement,
    });
    while (query.next()) |item| {
        const player_input: *c.PlayerInput = item.get(c.PlayerInput).?;
        const motion: *c.Motion = item.get(c.Motion).?;
        const movement: *c.Movement = item.get(c.Movement).?;

        const direction: rl.Vector2 = inputDirection(player_input);

        if (direction.length() > 0.0) {
            helpers.accelerate(motion, movement, direction, dt);
        }
    }
}

fn inputDirection(player_input: *const c.PlayerInput) rl.Vector2 {
    var input_direction = rl.Vector2.zero();

    if (player_input.move_up) input_direction.y -= 1;
    if (player_input.move_down) input_direction.y += 1;
    if (player_input.move_left) input_direction.x -= 1;
    if (player_input.move_right) input_direction.x += 1;

    if (input_direction.length() == 0.0) {
        return rl.Vector2.zero();
    }

    return rl.Vector2.normalize(input_direction);
}
