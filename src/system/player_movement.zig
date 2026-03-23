const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

const helpers = @import("helpers");

pub fn playerMovement(ecs: *ECS) void {
    const dt: f32 = rl.getFrameTime();
    const direction: rl.Vector2 = inputDirection();

    var query = ecs.query(.{
        c.Player,
        c.Motion,
        c.Movement,
    });
    while (query.next()) |item| {
        const motion: *c.Motion = item.get(c.Motion).?;
        const movement: *c.Movement = item.get(c.Movement).?;

        if (direction.length() > 0.0) {
            helpers.accelerate(motion, movement, direction, dt);
        }
    }
}

fn inputDirection() rl.Vector2 {
    var input_direction = rl.Vector2.zero();

    if (rl.isKeyDown(rl.KeyboardKey.w)) input_direction.y -= 1;
    if (rl.isKeyDown(rl.KeyboardKey.s)) input_direction.y += 1;
    if (rl.isKeyDown(rl.KeyboardKey.a)) input_direction.x -= 1;
    if (rl.isKeyDown(rl.KeyboardKey.d)) input_direction.x += 1;

    if (input_direction.length() == 0.0) {
        return rl.Vector2.zero();
    }

    return rl.Vector2.normalize(input_direction);
}
