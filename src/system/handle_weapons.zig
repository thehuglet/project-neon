const std = @import("std");

const rl = @import("raylib");

const Context = @import("context").Context;
const ECS = @import("ecs").ECS;
const e = @import("entity");
const c = @import("component");
const a = @import("asset");

const math = @import("math");
const helpers = @import("helpers");
const weapon = @import("weapon");

pub fn handleWeapons(
    ctx: *Context,
) void {
    const dt: f32 = rl.getFrameTime();
    const projectile_atlas = ctx.atlases.get(.projectile).?;

    var query = ctx.ecs.query(.{
        c.WeaponUseIntent,
        c.WeaponSlots,
        c.Transform,
    });
    while (query.next()) |item| {
        const use_intent: *c.WeaponUseIntent = item.get(c.WeaponUseIntent).?;
        const slots: *c.WeaponSlots = item.get(c.WeaponSlots).?;
        const transform: *c.Transform = item.get(c.Transform).?;

        for (&slots.slots) |*slot| {
            if (slot.* == null) continue;
            const slotted_weapon = &slot.*.?;

            // This is safe as long as the stats for the weapon are defined
            const stats: weapon.WeaponStats = weapon.STATS.get(slotted_weapon.id).?;

            const remaining_primary_cd = &slotted_weapon.remaining_primary_cooldown;
            const remaining_secondary_cd = &slotted_weapon.remaining_secondary_cooldown;

            remaining_primary_cd.* = @max(0.0, remaining_primary_cd.* - dt);
            remaining_secondary_cd.* = @max(0.0, remaining_secondary_cd.* - dt);

            // Trigger primary
            if (use_intent.use_primary_fire and remaining_primary_cd.* <= 0.0) {
                remaining_primary_cd.* = 1.0 / stats.primary.fire_rate;

                weapon.usePrimary(
                    &ctx.ecs,
                    ctx.rng,
                    slotted_weapon.id,
                    projectile_atlas,
                    item.entity_id,
                    transform,
                    ctx.mouse_pos,
                );
            }

            // Trigger secondary
            if (use_intent.use_secondary_fire and remaining_secondary_cd.* <= 0.0) {
                remaining_secondary_cd.* = 1.0 / stats.secondary.fire_rate;

                weapon.useSecondary(
                    &ctx.ecs,
                    ctx.rng,
                    slotted_weapon.id,
                    projectile_atlas,
                    item.entity_id,
                    transform,
                    ctx.mouse_pos,
                );
            }
        }
    }
}
