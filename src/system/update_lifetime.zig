const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn updateLifetime(ecs: *ECS) void {
    const dt: f32 = rl.getFrameTime();

    var query = ecs.query(.{
        c.Lifetime,
    });
    while (query.next()) |item| {
        const lifetime: *c.Lifetime = item.get(c.Lifetime).?;

        lifetime.remaining_sec = @max(0.0, lifetime.remaining_sec - dt);
    }
}
