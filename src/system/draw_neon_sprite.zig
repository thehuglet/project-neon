const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");
const a = @import("asset");
const math_helpers = @import("math_helpers");

pub fn drawNeonSprite(ecs: *ECS, shader: *const a.NeonSpriteShader) void {
    var query = ecs.query(.{
        c.Transform,
        c.NeonSprite,
    });
    while (query.next()) |item| {
        const transform: *c.Transform = item.get(c.Transform).?;
        const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;

        const dest_width: f32 = neon_sprite.base_texture_src.width * neon_sprite.options.scale * transform.scale;
        const dest_height: f32 = neon_sprite.base_texture_src.height * neon_sprite.options.scale * transform.scale;
        const origin: rl.Vector2 = neon_sprite.options.origin orelse .{ .x = dest_width / 2, .y = dest_height / 2 };
        const dest = rl.Rectangle{
            .x = transform.pos.x,
            .y = transform.pos.y,
            .width = dest_width,
            .height = dest_height,
        };

        // ------ Blurred sprite ------
        rl.beginShaderMode(shader.shader);
        const color_vec4: [4]f32 = a.colorToF32Array(neon_sprite.color);
        rl.setShaderValue(shader.shader, shader.u_color, &color_vec4, .vec4);

        const transform_rot_rad: f32 = transform.rotation_rad;
        const neon_sprite_rot_rad: f32 = neon_sprite.options.rotation_rad;
        const final_rotation_deg: f32 = (transform_rot_rad + neon_sprite_rot_rad) * math_helpers.RAD_TO_DEG;

        rl.drawTexturePro(
            neon_sprite.atlas.texture,
            neon_sprite.blur_texture_src,
            dest,
            origin,
            final_rotation_deg,
            rl.Color.white,
        );
        rl.endShaderMode();

        // ------ Base sprite ------
        rl.drawTexturePro(
            neon_sprite.atlas.texture,
            neon_sprite.base_texture_src,
            dest,
            origin,
            final_rotation_deg,
            rl.Color.white,
        );
    }
}
