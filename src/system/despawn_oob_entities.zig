const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn despawnOOBEntities(ecs: *ECS, native_width: f32, native_height: f32, margin: f32) void {
    var query = ecs.query(.{
        c.DespawnsWhenOOB,
        c.Transform,
    });
    while (query.next()) |item| {
        const transform: *c.Transform = item.get(c.Transform).?;

        const oob_left: bool = transform.pos.x < 0 - margin;
        const oob_top: bool = transform.pos.y < 0 - margin;
        const oob_right: bool = transform.pos.x > native_width + margin;
        const oob_bottom: bool = transform.pos.y > native_height + margin;

        if (oob_left or oob_top or oob_right or oob_bottom) {
            item.ecs.deleteEntity(item.entity_id);
        }
    }
}
