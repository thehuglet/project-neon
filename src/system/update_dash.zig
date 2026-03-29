const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const c = @import("component");

pub fn updateDash(ecs: *ECS) void {
    const dt: f32 = rl.getFrameTime();

    var query = ecs.query(.{
        c.Dashing,
        c.Transform,
        c.NeonSprite,
    });
    while (query.next()) |item| {
        const transform: *c.Transform = item.get(c.Transform).?;
        const dash: *c.Dashing = item.get(c.Dashing).?;
        const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;

        const move_distance = dash.speed * dt;

        if (move_distance >= dash.remaining_distance) {
            const final_move = dash.remaining_distance;
            transform.pos.x += dash.direction.x * final_move;
            transform.pos.y += dash.direction.y * final_move;
            ecs.removeComponent(item.entity_id, c.Dashing);
        } else {
            transform.pos.x += dash.direction.x * move_distance;
            transform.pos.y += dash.direction.y * move_distance;
            dash.remaining_distance -= move_distance;
        }

        switch (dash.trail) {
            .none => {},
            .ghost_spawner => |*data| {
                data.spawn_cooldown -= dt;

                if (data.spawn_cooldown <= 0.0) {
                    data.spawn_cooldown = 1.0 / data.spawn_rate;

                    spawnTrailGhostEntity(ecs, transform.*, neon_sprite);
                }
            },
        }
    }
}

fn spawnTrailGhostEntity(ecs: *ECS, transform: c.Transform, neon_sprite: *c.NeonSprite) void {
    const entity_id: EntityId = ecs.assignEntityId();

    const alpha_scale: f32 = 0.2;
    const alpha_scaled: u8 = @as(u8, @intFromFloat(@as(f32, @floatFromInt(neon_sprite.color.a)) * alpha_scale));
    const lifetime_sec: f32 = 0.1;

    const neon_sprite_new = c.NeonSprite{
        .atlas = neon_sprite.atlas,
        .sprite_index = neon_sprite.sprite_index,
        .color = neon_sprite.color,
        .rotation_rad = neon_sprite.rotation_rad,
        .scale = neon_sprite.scale,
        .origin = neon_sprite.origin,
        .tint_base = true,
    };

    ecs.addComponent(entity_id, c.DashTrailGhost{
        .initial_lifetime_sec = lifetime_sec,
        .remaining_lifetime_sec = lifetime_sec,
        .original_alpha = alpha_scaled,
        .original_scale = neon_sprite.scale,
        .hue_shift_over_lifetime = 1.75,
        .scale_over_lifetime = 1.5,
    });
    ecs.addComponent(entity_id, transform);
    ecs.addComponent(entity_id, neon_sprite_new);
}
