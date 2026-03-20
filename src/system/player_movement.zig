const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn playerMovement(ecs: *ECS) void {
    const input_direction: rl.Vector2 = inputDirection();
    const delta_time: f32 = rl.getFrameTime();

    var query = ecs.query(.{
        c.Player,
        c.Transform,
        c.MovementSpeed,
    });
    while (query.next()) |item| {
        const transform: *c.Transform = item.get(c.Transform).?;
        const movement_speed: *c.MovementSpeed = item.get(c.MovementSpeed).?;

        transform.pos = transform.pos.add(
            input_direction.scale(movement_speed.base * delta_time),
        );
    }
}

fn inputDirection() rl.Vector2 {
    var input_dir = rl.Vector2.zero();

    if (rl.isKeyDown(rl.KeyboardKey.w)) input_dir.y -= 1;
    if (rl.isKeyDown(rl.KeyboardKey.s)) input_dir.y += 1;
    if (rl.isKeyDown(rl.KeyboardKey.a)) input_dir.x -= 1;
    if (rl.isKeyDown(rl.KeyboardKey.d)) input_dir.x += 1;

    return rl.Vector2.normalize(input_dir);
}
