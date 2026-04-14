const Context = @import("context").Context;

const std = @import("std");
const rl = @import("raylib");
const c = @import("component");
const math = @import("math");
const helpers = @import("helpers");

pub fn chaseEntity(ctx: *Context) void {
    const dt: f32 = rl.getFrameTime();

    var query = ctx.ecs.query(.{
        c.ChaseEntity,
        c.TargetedEntity,
        c.Motion,
        c.Movement,
        c.Transform,
    });
    while (query.next()) |item| {
        const chase_entity: *c.ChaseEntity = item.get(c.ChaseEntity).?;
        const targeted_entity: *c.TargetedEntity = item.get(c.TargetedEntity).?;
        const motion: *c.Motion = item.get(c.Motion).?;
        const movement: *c.Movement = item.get(c.Movement).?;
        const transform: *c.Transform = item.get(c.Transform).?;

        const target_transform = ctx.ecs.getComponent(targeted_entity.entity_id, c.Transform) orelse {
            std.log.err(
                "[Invalid target] Entity {f} tried chasing EntityId {f} with no Transform component",
                .{
                    item.entity_id,
                    targeted_entity.entity_id,
                },
            );
            continue;
        };

        const direction_to_target: rl.Vector2 = math.direction(transform.pos, target_transform.pos);
        const target_angle: f32 = math.vec2ToAngle(direction_to_target);
        const current_angle: f32 = math.vec2ToAngle(chase_entity.facing_direction);

        const speed: f32 = motion.velocity.length();
        const speed_factor: f32 = if (movement.max_speed > 0)
            @min(speed / movement.max_speed, 1.0)
        else
            0.0;
        const turn_rate_multiplier: f32 = 1.0 - speed_factor * chase_entity.accel_impact_on_turn_rate;
        const new_facing_angle: f32 = math.lerpAngle(
            current_angle,
            target_angle,
            chase_entity.turn_rate * turn_rate_multiplier * dt,
        );
        chase_entity.facing_direction = math.angleToVec2(new_facing_angle);

        const angle_diff: f32 = math.wrapAnglePi(target_angle - current_angle);
        const target_in_cone: bool = @abs(angle_diff) < chase_entity.accel_cone_angle;

        if (target_in_cone) {
            helpers.accelerate(
                motion,
                movement,
                chase_entity.facing_direction,
                dt,
            );
        }
    }
}
