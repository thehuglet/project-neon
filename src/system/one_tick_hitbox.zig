const ECS = @import("ecs").ECS;

const c = @import("component");

pub fn oneTickHitbox(ecs: *ECS) void {
    var query = ecs.query(.{
        c.OneTickHitbox,
        c.Hitbox,
    });
    while (query.next()) |item| {
        const hitbox: *c.Hitbox = item.get(c.Hitbox).?;

        hitbox.active = false;
        ecs.removeComponent(item.entity_id, c.OneTickHitbox);
    }
}
