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

        const color: rl.Color = if (hitbox.active) rl.Color.red else rl.Color.init(100, 80, 80, 255);
        const radius: f32 = hitbox.radius * transform.scale;

        rl.drawCircleLines(
            @intFromFloat(transform.pos.x),
            @intFromFloat(transform.pos.y),
            radius,
            color,
        );
        rl.drawCircle(
            @intFromFloat(transform.pos.x),
            @intFromFloat(transform.pos.y),
            radius,
            color.alpha(0.5),
        );
    }
}
