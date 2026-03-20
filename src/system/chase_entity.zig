const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");
const math = @import("math");

pub fn chaseEntity(ecs: *ECS) void {
    const delta_time: f32 = rl.getFrameTime();

    var query = ecs.query(.{
        c.ChaseEntity,
        c.Transform,
        c.MovementSpeed,
        c.DynamicMovementSpeed,
    });
    while (query.next()) |item| {
        const transform: *c.Transform = item.get(c.Transform).?;
        const chase_entity: *c.ChaseEntity = item.get(c.ChaseEntity).?;
        const movement_speed: *c.MovementSpeed = item.get(c.MovementSpeed).?;
        const dynamic_movement_speed: *c.DynamicMovementSpeed = item.get(c.DynamicMovementSpeed).?;

        const target_transform = ecs.getComponent(chase_entity.entity_id, c.Transform) orelse {
            std.log.err(
                "[Invalid target] Entity {d} tried chasing entity {d} with no Transform component",
                .{ item.entity_id, chase_entity.entity_id },
            );
            continue;
        };

        const dir_to_target: rl.Vector2 = math.direction(transform.pos, target_transform.pos);
        const target_angle: f32 = math.vec2ToAngle(dir_to_target);
        const current_angle: f32 = math.vec2ToAngle(chase_entity.facing_direction);

        // Front cone detection
        const angle_diff: f32 = math.wrapAnglePi(target_angle - current_angle);
        const target_in_cone: bool = @abs(angle_diff) < chase_entity.acceleration_cone_angle;

        // Acceleration & deceleration
        if (target_in_cone) {
            dynamic_movement_speed.current_speed_scale += dynamic_movement_speed.acceleration_rate * delta_time;
        } else {
            dynamic_movement_speed.current_speed_scale -= dynamic_movement_speed.deceleration_rate * delta_time;
        }
        dynamic_movement_speed.current_speed_scale = std.math.clamp(
            dynamic_movement_speed.current_speed_scale,
            dynamic_movement_speed.min_speed_scale,
            dynamic_movement_speed.max_speed_scale,
        );

        // Turn rate multiplier
        const speed_scale: f32 = dynamic_movement_speed.current_speed_scale; // range [min..max]
        const speed_factor: f32 = (speed_scale - dynamic_movement_speed.min_speed_scale) /
            (dynamic_movement_speed.max_speed_scale - dynamic_movement_speed.min_speed_scale);
        const turn_rate_multiplier: f32 = 1.0 - speed_factor;

        const new_angle: f32 = math.lerpAngle(
            current_angle,
            target_angle,
            chase_entity.turn_speed * turn_rate_multiplier * delta_time,
        );
        chase_entity.facing_direction = math.angleToVec2(new_angle);

        transform.pos = transform.pos.add(
            chase_entity.facing_direction.scale(
                movement_speed.base * dynamic_movement_speed.current_speed_scale * delta_time,
            ),
        );
    }
}
