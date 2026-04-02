const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn lifetimeDespawn(ecs: *ECS) void {
    var query = ecs.query(.{
        c.Lifetime,
    });
    while (query.next()) |item| {
        const lifetime: *c.Lifetime = item.get(c.Lifetime).?;

        if (lifetime.remaining_sec <= 0.0) {
            ecs.deleteEntity(item.entity_id);
        }
    }
}
