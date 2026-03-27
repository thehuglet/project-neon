const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn spinCosmetic(ecs: *ECS) void {
    const dt: f32 = rl.getFrameTime();

    var query = ecs.query(.{
        c.SpinCosmetic,
        c.NeonSprite,
    });
    while (query.next()) |item| {
        const spin: *c.SpinCosmetic = item.get(c.SpinCosmetic).?;
        const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;

        const spin_direction: f32 = if (spin.clockwise) 1.0 else -1.0;
        neon_sprite.rotation_rad += spin_direction * spin.speed * 0.2 * dt;
    }
}
