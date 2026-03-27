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
    });
    while (hit_query.next()) |hit_item| {
        const hit_transform = hit_item.get(c.Transform).?;
        const hitbox = hit_item.get(c.Hitbox).?;

        for (0..hurt_ids.items.len) |i| {
            if (hit_item.entity_id == hurt_ids.items[i]) continue;
            if ((hitbox.mask & hurt_layers.items[i]) == 0) continue;

            const dx = hit_transform.pos.x - hurt_positions.items[i].x;
            const dy = hit_transform.pos.y - hurt_positions.items[i].y;
            const dist_sq = dx * dx + dy * dy;
            const rad_sum = hitbox.radius + hurt_radii.items[i];
            if (dist_sq < rad_sum * rad_sum) {
                const receiver_entity_id: EntityId = hurt_ids.items[i];
                hit(ecs, receiver_entity_id, hit_item.entity_id);
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
