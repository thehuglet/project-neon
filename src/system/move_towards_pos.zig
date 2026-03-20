const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");
const math = @import("math");

pub fn moveTowardsPos(ecs: *ECS) void {
    const delta_time: f32 = rl.getFrameTime();

    var query = ecs.query(.{
        c.MoveTowardsPos,
        c.Transform,
    });
    while (query.next()) |item| {
        const transform: *c.Transform = item.get(c.Transform).?;
        const move_towards_pos: *c.MoveTowardsPos = item.get(c.MoveTowardsPos).?;

        const target_pos: rl.Vector2 = move_towards_pos.pos orelse continue;

        const direction_to_target = math.direction(transform.pos, target_pos);

        transform.pos = transform.pos.add(
            direction_to_target.scale(600.0 * delta_time),
        );

        // transform.pos = transform.pos.add(
        //     input_direction.scale(600.0 * delta_time),
        // );
    }
}
