const Context = @import("context").Context;

const rl = @import("raylib");
const c = @import("component");

pub fn playerDashInit(ctx: *Context) void {
    var query = ctx.ecs.query(.{
        c.PlayerInput,
    });
    while (query.next()) |item| {
        const player_input: *c.PlayerInput = item.get(c.PlayerInput).?;

        const is_dashing: bool = ctx.ecs.hasComponent(item.entity_id, c.Dashing);
        const direction: rl.Vector2 = inputDirection(player_input);

        if (player_input.dash and !is_dashing and direction.length() != 0.0) {
            ctx.ecs.addComponent(item.entity_id, c.Dashing{
                .speed = 2000.0,
                .remaining_distance = 200.0,
                .direction = direction,
                .trail = .{
                    .ghost_spawner = .{
                        .spawn_rate = 150.0,
                    },
                },
            });
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
