const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");
const a = @import("asset");
const math_helpers = @import("math_helpers");

pub fn playerRotateFacingMouseCosmetic(ecs: *ECS) void {
    const mouse_pos: rl.Vector2 = rl.getMousePosition();
    const delta_time: f32 = rl.getFrameTime();

    var query = ecs.query(.{
        c.Player,
        c.Transform,
        c.NeonSprite,
    });
    while (query.next()) |item| {
        const transform: *c.Transform = item.get(c.Transform).?;
        const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;

        const dir_to_mouse = math_helpers.direction(
            transform.pos,
            mouse_pos,
        );

        const target_angle_rad: f32 = math_helpers.vec2ToAngle(dir_to_mouse);
        neon_sprite.options.rotation_rad = math_helpers.lerpAngle(
            neon_sprite.options.rotation_rad,
            target_angle_rad,
            delta_time * 10.0,
        );
    }
}
