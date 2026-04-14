const Context = @import("context").Context;

const rl = @import("raylib");
const c = @import("component");
const helpers = @import("helpers");

pub fn playerDashInit(ctx: *Context) void {
    var query = ctx.ecs.query(.{
        c.Player,
    });
    while (query.next()) |item| {
        const is_dashing: bool = ctx.ecs.hasComponent(item.entity_id, c.Dashing);
        const input_dir: rl.Vector2 = helpers.playerInputDirection(&ctx.player_input_state);

        if (ctx.player_input_state.dash and !is_dashing and input_dir.length() != 0.0) {
            ctx.ecs.addComponent(item.entity_id, c.Dashing{
                .speed = 2000.0,
                .remaining_distance = 200.0,
                .direction = input_dir,
                .trail = .{
                    .ghost_spawner = .{
                        .spawn_rate = 150.0,
                    },
                },
            });
        }
    }
}
