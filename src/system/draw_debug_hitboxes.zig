const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn drawDebugHitboxes(ecs: *ECS) void {
    var query = ecs.query(.{
        c.Hitbox,
        c.Transform,
    });
    while (query.next()) |item| {
        const hitbox: *c.Hitbox = item.get(c.Hitbox).?;
        const transform: *c.Transform = item.get(c.Transform).?;

        rl.drawCircleLines(
            @intFromFloat(transform.pos.x),
            @intFromFloat(transform.pos.y),
            hitbox.radius,
            rl.Color.red,
        );
        rl.drawCircle(
            @intFromFloat(transform.pos.x),
            @intFromFloat(transform.pos.y),
            hitbox.radius,
            rl.Color.red.alpha(0.5),
        );
    }
}
