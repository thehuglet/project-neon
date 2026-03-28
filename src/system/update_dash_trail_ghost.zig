const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn updateDashTrailGhost(ecs: *ECS) void {
    const dt: f32 = rl.getFrameTime();

    var query = ecs.query(.{
        c.DashTrailGhost,
        c.NeonSprite,
    });
    while (query.next()) |item| {
        const ghost: *c.DashTrailGhost = item.get(c.DashTrailGhost).?;
        const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;

        // Lifetime
        ghost.remaining_lifetime_sec -= dt;

        if (ghost.remaining_lifetime_sec <= 0.0) {
            ecs.deleteEntity(item.entity_id);
        }

        // Alpha fading over lifetime
        const t: f32 = @min(ghost.remaining_lifetime_sec / ghost.initial_lifetime_sec, 1.0);
        const alpha: f32 = @as(f32, @floatFromInt(ghost.original_alpha)) * t;
        const clamped_alpha: f32 = @max(0.0, @min(alpha, 255.0));
        neon_sprite.color.a = @as(u8, @intFromFloat(clamped_alpha));
    }
}
