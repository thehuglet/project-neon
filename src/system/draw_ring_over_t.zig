const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn drawRingOverT(ecs: *ECS) void {
    const thickness: f32 = 5.0;

    var query = ecs.query(.{
        c.RingOverT,
        c.Transform,
    });
    while (query.next()) |item| {
        const ring: *c.RingOverT = item.get(c.RingOverT).?;
        const transform: *c.Transform = item.get(c.Transform).?;

        const t = ring.t;

        const radius = t * ring.radius * (1.0 + ring.max_radius_at_t);

        const alpha: f32 = blk: {
            if (t < ring.fade_at_t) break :blk 1.0;

            const fade_t = (t - ring.fade_at_t) / (1.0 - ring.fade_at_t);
            break :blk 1.0 - fade_t;
        };

        const color = rl.Color.red.alpha(alpha);

        rl.drawRing(
            transform.pos,
            radius - thickness / 2.0,
            radius + thickness / 2.0,
            0,
            360,
            64,
            color,
        );

        // DrawRing(center, radius - thickness/2.0f, radius + thickness/2.0f, 0, 360, 64, RED);
    }
}
