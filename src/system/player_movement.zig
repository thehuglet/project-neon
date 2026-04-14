const Context = @import("context").Context;
const PlayerInputState = @import("context").PlyerInputState;

const rl = @import("raylib");
const c = @import("component");
const helpers = @import("helpers");

pub fn playerMovement(ctx: *Context) void {
    const dt: f32 = rl.getFrameTime();

    var query = ctx.ecs.query(.{
        c.Motion,
        c.Movement,
    });
    while (query.next()) |item| {
        const motion: *c.Motion = item.get(c.Motion).?;
        const movement: *c.Movement = item.get(c.Movement).?;

        const direction: rl.Vector2 = helpers.playerInputDirection(&ctx.player_input_state);
        const is_dashing: bool = ctx.ecs.hasComponent(item.entity_id, c.Dashing);

        if (direction.length() > 0.0 and !is_dashing) {
            helpers.motion_accelerate(motion, movement, direction, dt);
        }
    }
}
