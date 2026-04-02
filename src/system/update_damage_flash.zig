const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn updateDamageFlash(ecs: *ECS) void {
    const dt: f32 = rl.getFrameTime();

    var query = ecs.query(.{
        c.DamageFlash,
    });
    while (query.next()) |item| {
        const dmg_flash: *c.DamageFlash = item.get(c.DamageFlash).?;

        // Lifetime
        dmg_flash.remaining_duration_sec -= dt;

        if (dmg_flash.remaining_duration_sec <= 0.0) {
            ecs.removeComponent(item.entity_id, c.DamageFlash);
        }

        const t: f32 = @min(dmg_flash.remaining_duration_sec / dmg_flash.duration_sec, 1.0);

        // Lightness shift
        dmg_flash.current_lightness_shift = dmg_flash.peak_lightness_shift * t;

        // Alpha scale
        dmg_flash.current_alpha_scale = 1.0 + (dmg_flash.peak_alpha_scale - 1.0) * (1.0 - t);
    }
}
