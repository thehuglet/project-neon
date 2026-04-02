const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn updateRingOverTLifetime(ecs: *ECS) void {
    var query = ecs.query(.{
        c.RingOverT,
        c.Lifetime,
    });
    while (query.next()) |item| {
        const ring: *c.RingOverT = item.get(c.RingOverT).?;
        const lifetime: *c.Lifetime = item.get(c.Lifetime).?;

        ring.t = 1.0 - (lifetime.remaining_sec / lifetime.initial_sec);
    }
}
