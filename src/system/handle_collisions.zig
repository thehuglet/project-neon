const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const c = @import("component");

pub fn handleCollisions(
    ecs: *ECS,
    allocator: std.mem.Allocator,
    hurt_ids: *std.ArrayList(EntityId),
    hurt_positions: *std.ArrayList(rl.Vector2),
    hurt_radii: *std.ArrayList(f32),
    hurt_layers: *std.ArrayList(u32),
) void {
    const dt: f32 = rl.getFrameTime();

    // Collect hurtboxes
    var hurt_query = ecs.query(.{
        c.Transform,
        c.Hurtbox,
    });
    while (hurt_query.next()) |hurt_item| {
        const transform = hurt_item.get(c.Transform).?;
        const hurtbox = hurt_item.get(c.Hurtbox).?;
        hurt_ids.append(allocator, hurt_item.entity_id) catch @panic("OOM");
        hurt_positions.append(allocator, transform.pos) catch @panic("OOM");
        hurt_radii.append(allocator, hurtbox.radius) catch @panic("OOM");
        hurt_layers.append(allocator, hurtbox.layer) catch @panic("OOM");
    }

    // Compare against hitboxes
    var hit_query = ecs.query(.{
        c.Transform,
        c.Hitbox,
        c.Motion,
    });
    while (hit_query.next()) |hit_item| {
        const hit_transform = hit_item.get(c.Transform).?;
        const hitbox = hit_item.get(c.Hitbox).?;
        const motion = hit_item.get(c.Motion).?;

        const future_pos = rl.math.vector2Add(
            hit_transform.pos,
            rl.math.vector2Scale(motion.velocity, dt),
        );

        for (0..hurt_ids.items.len) |i| {
            if (hit_item.entity_id == hurt_ids.items[i]) continue;
            if ((hitbox.mask & hurt_layers.items[i]) == 0) continue;

            const hurt_center = hurt_positions.items[i];
            const hurt_radius = hurt_radii.items[i];
            const total_radius = hitbox.radius + hurt_radius;

            // Swept test: line segment from current pos to future pos
            if (circleLineSegmentCollision(
                hurt_center,
                total_radius,
                hit_transform.pos,
                future_pos,
            )) {
                hit(ecs, hurt_ids.items[i], hit_item.entity_id);
            }
        }
    }
}

fn hit(ecs: *ECS, receiver: EntityId, attacker: EntityId) void {
    if (ecs.getComponent(receiver, c.HealthLives)) |health| {
        health.lives -|= 1;
    }

    ecs.deleteEntity(attacker);
}

fn circleLineSegmentCollision(
    center: rl.Vector2,
    radius: f32,
    a: rl.Vector2,
    b: rl.Vector2,
) bool {
    const ab = rl.math.vector2Subtract(b, a);
    const ac = rl.math.vector2Subtract(center, a);
    const dot_ab_ab = rl.math.vector2DotProduct(ab, ab);

    if (dot_ab_ab == 0.0) {
        const diff = rl.math.vector2Subtract(center, a);
        return diff.x * diff.x + diff.y * diff.y <= radius * radius;
    }

    const t = rl.math.vector2DotProduct(ac, ab) / dot_ab_ab;
    const t_clamped = std.math.clamp(t, 0.0, 1.0);
    const closest = rl.math.vector2Add(a, rl.math.vector2Scale(ab, t_clamped));
    const diff = rl.math.vector2Subtract(closest, center);
    const dist_sq = diff.x * diff.x + diff.y * diff.y;
    return dist_sq <= radius * radius;
}
