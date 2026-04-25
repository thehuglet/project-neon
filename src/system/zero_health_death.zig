const std = @import("std");

const rl = @import("raylib");

const Context = @import("context").Context;
const EntityId = @import("ecs").EntityId;

const c = @import("component");

const helpers = @import("helpers");
const math = @import("math");

pub fn zeroHealthDeath(ctx: *Context) void {
    // Standard health
    {
        var query = ctx.ecs.query(.{
            c.Health,
            // c.NeonSprite,
            // c.Transform,
        });
        while (query.next()) |item| {
            const health: *c.Health = item.get(c.Health).?;
            // const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;
            // const transform: *c.Transform = item.get(c.Transform).?;

            // const maybe_motion: ?*c.Motion = item.get(c.Motion);
            std.debug.print("health: {}\n", .{health});

            if (health.health <= 0.0) {
                ctx.ecs.addComponent(item.entity_id, c.Dead{});
            }

            // if (health.health <= 0.0) {
            //     for (0..10) |_| {
            //         // TODO: move this out of here into its own dedicated system
            //         spawnDeathParticles(
            //             ecs,
            //             rng,
            //             neon_sprite,
            //             transform,
            //             maybe_motion,
            //         );
            //     }

            //     ecs.deleteEntity(item.entity_id);
            // }
        }
    }
}

// fn spawnDeathParticles(
//     ecs: *ECS,
//     rng: std.Random,
//     neon_sprite: *c.NeonSprite,
//     transform: *c.Transform,
//     maybe_motion: ?*c.Motion,
// ) void {
//     const entity_id: EntityId = ecs.assignEntityId();

//     const lifetime_sec: f32 = 1.0;
//     const direction: rl.Vector2 = math.angleToVec2(helpers.randomFloatRange(rng, 0.0, std.math.pi * 2.0));
//     const force_magnitude: f32 = helpers.randomFloatRange(rng, 20.0, 150.0);

//     const motion_velocity: rl.Vector2 = if (maybe_motion) |m| m.velocity else rl.Vector2.zero();

//     const final_velocity: rl.Vector2 = rl.math.vector2Add(
//         direction.scale(force_magnitude),
//         motion_velocity.scale(0.75),
//     );

//     // Inherits the owners motion component if applicable
//     var motion: c.Motion = if (maybe_motion) |m| m.* else c.Motion{
//         .mass = 10.0,
//         .friction = 1.0,
//     };

//     motion.velocity = final_velocity;

//     ecs.addComponent(entity_id, c.DashTrailGhost{
//         .lifetime_sec = lifetime_sec,
//         .remaining_lifetime_sec = lifetime_sec,
//         .hue_shift_over_lifetime = 2.0,
//         .scale_over_lifetime = 0.0,
//     });
//     ecs.addComponent(entity_id, motion);
//     ecs.addComponent(entity_id, c.Transform{
//         .pos = transform.pos,
//         .rotation_rad = helpers.randomFloatRange(rng, 0.0, std.math.pi * 2.0),
//         .scale = transform.scale,
//     });
//     ecs.addComponent(entity_id, c.NeonSprite{
//         .atlas = neon_sprite.atlas,
//         .sprite_index = neon_sprite.sprite_index,
//         .color = neon_sprite.color.alpha(0.35),
//         .rotation_rad = helpers.randomFloatRange(rng, 0.0, std.math.pi * 2.0),
//         .scale = neon_sprite.scale * 0.5,
//         .origin = neon_sprite.origin,
//         .tint_base = neon_sprite.tint_base,
//     });
// }
