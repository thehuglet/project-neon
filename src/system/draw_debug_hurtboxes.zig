const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn drawDebugHurtboxes(ecs: *ECS) void {
    var query = ecs.query(.{
        c.Hurtbox,
        c.Transform,
    });
    while (query.next()) |item| {
        const hurtbox: *c.Hurtbox = item.get(c.Hurtbox).?;
        const transform: *c.Transform = item.get(c.Transform).?;

        rl.drawCircleLines(
            @intFromFloat(transform.pos.x),
            @intFromFloat(transform.pos.y),
            hurtbox.radius,
            rl.Color.lime,
        );
        rl.drawCircle(
            @intFromFloat(transform.pos.x),
            @intFromFloat(transform.pos.y),
            hurtbox.radius,
            rl.Color.lime.alpha(0.5),
        );
    }
}
