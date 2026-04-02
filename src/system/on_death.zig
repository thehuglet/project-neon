const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn onDeath(ecs: *ECS) void {
    var query = ecs.query(.{
        c.OnDeath,
    });
    while (query.next()) |item| {
        const on_death: *c.OnDeath = item.get(c.OnDeath).?;

        if (ecs.entityIsAlive(item.entity_id)) {
            continue;
        }

        on_death.callback(ecs, item.entity_id, on_death.data);
    }
}
