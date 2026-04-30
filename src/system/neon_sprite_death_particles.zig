const rl = @import("raylib");
const c = @import("component");
const particle = @import("particle");

const Context = @import("context").Context;

pub fn neonSpriteDeathParticles(ctx: *Context) void {
    var query = ctx.ecs.query(.{
        c.Dead,
        c.DeathParticles,
        c.NeonSprite,
        c.Transform,
    });
    while (query.next()) |item| {
        const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;
        const death_particles: *c.DeathParticles = item.get(c.DeathParticles).?;
        const transform: *c.Transform = item.get(c.Transform).?;

        const maybe_motion: ?*c.Motion = item.get(c.Motion);
        var extra_velocity = rl.Vector2.zero();
        if (maybe_motion) |motion| {
            extra_velocity = motion.velocity.scale(death_particles.extra_velocity_factor);
        }

        particle.spawnBurst(
            &ctx.particle_system,
            ctx.rng,
            transform.pos,
            .{
                .texture = .{
                    .atlas_id = death_particles.texture.atlas_id,
                    .cell_index = death_particles.texture.cell_index,
                },
                .speed = .{ .range = .{
                    .min = 50.0 * death_particles.speed_factor,
                    .max = 1000.0 * death_particles.speed_factor,
                } },
                .extra_velocity = extra_velocity,
                .color = neon_sprite.color.alpha(0.3),
                .clean_colorize_factor = 0.5,
                .scale = .{ .flat = 140.0 },
                .lifetime_sec = .{ .range = .{
                    .min = 0.5,
                    .max = 0.7,
                } },
                .alpha_over_t = 0.0,
                .scale_over_t = 0.0,
                .hue_shift_over_t = 1.0,
                .spin_speed = .{ .range = .{
                    .min = -8.0,
                    .max = 8.0,
                } },
            },
            .{
                .count = death_particles.count,
            },
        );
    }
}
