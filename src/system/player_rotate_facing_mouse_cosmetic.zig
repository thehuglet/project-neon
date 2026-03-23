const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");
const math = @import("math");

pub fn playerRotateFacingMouseCosmetic(ecs: *ECS, mouse_pos: rl.Vector2) void {
    const delta_time: f32 = rl.getFrameTime();

    var query = ecs.query(.{
        c.Player,
        c.Transform,
        c.NeonSprite,
    });
    while (query.next()) |item| {
        const transform: *c.Transform = item.get(c.Transform).?;
        const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;

        const dir_to_mouse = math.direction(
            transform.pos,
            mouse_pos,
        );

        const target_angle_rad: f32 = math.vec2ToAngle(dir_to_mouse);
        neon_sprite.rotation_rad = math.lerpAngle(
            neon_sprite.rotation_rad,
            target_angle_rad,
            delta_time * 10.0,
        );
    }
}
