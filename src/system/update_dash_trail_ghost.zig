const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn updateDashTrailGhost(ecs: *ECS) void {
    const dt: f32 = rl.getFrameTime();

    var query = ecs.query(.{
        c.DashTrailGhost,
    });
    while (query.next()) |item| {
        const ghost: *c.DashTrailGhost = item.get(c.DashTrailGhost).?;

        // Lifetime
        ghost.remaining_lifetime_sec -= dt;

        if (ghost.remaining_lifetime_sec <= 0.0) {
            ecs.deleteEntity(item.entity_id);
        }

        const t: f32 = @min(ghost.remaining_lifetime_sec / ghost.lifetime_sec, 1.0);

        // Alpha fading
        ghost.current_alpha_scale = t;

        // Hue shifting
        ghost.current_hue_shift = ghost.hue_shift_over_lifetime * (1.0 - t);

        // Scale
        // ghost.current_scale = ghost.scale_over_lifetime * (1.0 - t);
        ghost.current_scale = 1.0 + (ghost.scale_over_lifetime - 1.0) * (1.0 - t);
    }
}
