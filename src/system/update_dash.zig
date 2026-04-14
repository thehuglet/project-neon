const Context = @import("context").Context;
const EntityId = @import("ecs").EntityId;

const rl = @import("raylib");
const c = @import("component");

pub fn updateDash(ctx: *Context) void {
    const dt: f32 = rl.getFrameTime();

    var query = ctx.ecs.query(.{
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
            ctx.ecs.removeComponent(item.entity_id, c.Dashing);
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

                    spawnTrailGhostEntity(ctx, transform.*, neon_sprite);
                }
            },
        }
    }
}

fn spawnTrailGhostEntity(ctx: *Context, transform: c.Transform, neon_sprite: *c.NeonSprite) void {
    const entity_id: EntityId = ctx.ecs.assignEntityId();

    const lifetime_sec: f32 = 0.1;

    const neon_sprite_new = c.NeonSprite{
        .atlas = neon_sprite.atlas,
        .sprite_index = neon_sprite.sprite_index,
        .color = neon_sprite.color.alpha(0.4),
        .rotation_rad = neon_sprite.rotation_rad,
        .scale = neon_sprite.scale,
        .origin = neon_sprite.origin,
        .tint_base = true,
    };

    ctx.ecs.addComponent(entity_id, c.DashTrailGhost{
        .lifetime_sec = lifetime_sec,
        .remaining_lifetime_sec = lifetime_sec,
        .hue_shift_over_lifetime = 1.75,
        .scale_over_lifetime = 1.5,
    });
    ctx.ecs.addComponent(entity_id, transform);
    ctx.ecs.addComponent(entity_id, neon_sprite_new);
}
