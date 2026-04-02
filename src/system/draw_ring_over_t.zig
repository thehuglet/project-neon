const std = @import("std");

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

        const radius: f32 = blk: {
            if (t >= ring.max_radius_at_t) break :blk ring.radius;

            const progress = t / ring.max_radius_at_t;
            break :blk ring.radius * std.math.pow(f32, progress, 1.0 / 3.0);
        };

        const alpha: f32 = blk: {
            if (t < ring.fade_in_at_t) {
                break :blk t / ring.fade_in_at_t;
            } else if (t < ring.fade_out_at_t) {
                break :blk 1.0;
            } else {
                const fade_t = (t - ring.fade_out_at_t) / (1.0 - ring.fade_out_at_t);
                break :blk 1.0 - fade_t;
            }
        };

        const color = rl.Color.red.alpha(alpha / 3.0);

        rl.drawRing(
            transform.pos,
            radius - thickness / 2.0,
            radius + thickness / 2.0,
            0,
            360,
            64,
            color,
        );
    }
}
