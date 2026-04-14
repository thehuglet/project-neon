const Context = @import("context").Context;
const EntityId = @import("ecs").EntityId;

const std = @import("std");
const rl = @import("raylib");
const c = @import("component");

pub fn handleCollisions(ctx: *Context) void {
    const dt: f32 = rl.getFrameTime();

    const hurt_ids = &ctx.temp.hurt_ids;
    const hurt_positions = &ctx.temp.hurt_positions;
    const hurt_radii = &ctx.temp.hurt_radii;
    const hurt_layers = &ctx.temp.hurt_layers;

    // Collect hurtboxes
    {
        var query = ctx.ecs.query(.{
            c.Transform,
            c.Hurtbox,
        });
        while (query.next()) |item| {
            const transform: *c.Transform = item.get(c.Transform).?;
            const hurtbox: *c.Hurtbox = item.get(c.Hurtbox).?;

            hurt_ids.append(ctx.allocator, item.entity_id) catch @panic("OOM");
            hurt_positions.append(ctx.allocator, transform.pos) catch @panic("OOM");
            hurt_radii.append(ctx.allocator, hurtbox.radius * transform.scale) catch @panic("OOM");
            hurt_layers.append(ctx.allocator, hurtbox.layer) catch @panic("OOM");
        }
    }

    // Compare against hitboxes
    {
        var query = ctx.ecs.query(.{
            c.Transform,
            c.Hitbox,
        });
        while (query.next()) |item| {
            const transform: *c.Transform = item.get(c.Transform).?;
            const hitbox: *c.Hitbox = item.get(c.Hitbox).?;

            if (!hitbox.active) {
                continue;
            }

            for (0..hurt_ids.items.len) |i| {
                const tried_hitting_self: bool = item.entity_id == hurt_ids.items[i];
                const collision_layer_mismatch: bool = !hitbox.mask.intersects(hurt_layers.items[i]);
                // const collision_layer_mismatch: bool = (hitbox.mask & hurt_layers.items[i]) == 0;
                const attacker_is_dead: bool = !ctx.ecs.entityIsAlive(item.entity_id);

                if (tried_hitting_self or collision_layer_mismatch or attacker_is_dead) {
                    continue;
                }

                const hurt_center = hurt_positions.items[i];
                const hurt_radius = hurt_radii.items[i];
                const total_radius = hitbox.radius * transform.scale + hurt_radius;

                const collides: bool = blk: {
                    const maybe_motion: ?*c.Motion = item.get(c.Motion);

                    if (maybe_motion) |motion| {
                        const future_pos = rl.math.vector2Add(
                            transform.pos,
                            rl.math.vector2Scale(motion.velocity, dt),
                        );
                        const collides: bool = circleLineSegmentCollision(
                            hurt_center,
                            total_radius,
                            transform.pos,
                            future_pos,
                        );
                        break :blk collides;
                    } else {
                        const dx = transform.pos.x - hurt_center.x;
                        const dy = transform.pos.y - hurt_center.y;
                        const collides: bool = (dx * dx + dy * dy) < total_radius * total_radius;
                        break :blk collides;
                    }
                };

                if (collides) {
                    hit(
                        ctx,
                        hurt_ids.items[i],
                        item.entity_id,
                        hitbox,
                    );
                }
            }
        }
    }
}

fn hit(ctx: *Context, receiver: EntityId, attacker: EntityId, hitbox: *c.Hitbox) void {
    dmg_application: {
        const receiver_health: *c.Health = ctx.ecs.getComponent(receiver, c.Health) orelse {
            break :dmg_application;
        };

        receiver_health.health -= hitbox.damage;
    }

    // Dmg flash
    {
        const duration = 0.15;
        const maybe_existing_dmg_flash: ?*c.DamageFlash = ctx.ecs.getComponent(receiver, c.DamageFlash);

        if (maybe_existing_dmg_flash) |existing_dmg_flash| {
            existing_dmg_flash.remaining_duration_sec = duration;
        } else {
            ctx.ecs.addComponent(receiver, c.DamageFlash{
                .duration_sec = duration,
                .remaining_duration_sec = duration,
                .peak_lightness_shift = 3.0,
                .peak_alpha_scale = 1.3,
            });
        }
    }

    owner_lumen_generation: {
        // Attacker needs to have an owner
        const owner: *c.Owner = ctx.ecs.getComponent(attacker, c.Owner) orelse {
            break :owner_lumen_generation;
        };

        // Owner needs to have a lumen component
        const lumen: *c.Lumen = ctx.ecs.getComponent(owner.entity_id, c.Lumen) orelse {
            break :owner_lumen_generation;
        };

        // Attacker needs to be able to generate lumen
        const generates_lumen: *c.GeneratesLumen = ctx.ecs.getComponent(attacker, c.GeneratesLumen) orelse {
            break :owner_lumen_generation;
        };

        lumen.amount = std.math.clamp(
            lumen.amount + generates_lumen.amount,
            0.0,
            lumen.max_amount,
        );
    }

    impact_piercing: {
        const stats: *c.ProjectileWeaponsStats = ctx.ecs.getComponent(attacker, c.ProjectileWeaponsStats) orelse {
            break :impact_piercing;
        };

        // TODO: this is temporary, piercing currently doesnt get decreased, fix this
        if (stats.stats.projectile == .impact and stats.stats.projectile.impact.piercing == 1) {
            ctx.ecs.deleteEntity(attacker);
        }

        if (stats.stats.projectile == .explosion) {
            ctx.ecs.deleteEntity(attacker);
        }
    }
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
