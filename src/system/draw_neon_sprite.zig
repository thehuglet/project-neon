const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");
const a = @import("asset");
const math = @import("math");

pub fn drawNeonSprite(ecs: *ECS, shader: *const a.NeonSpriteShader) void {
    // Drawing is done in two passes due to raylib lacking z-indexing:
    // - First pass: All the blur sprites are drawn
    // - Second pass: All normal sprites are drawn
    //
    // This makes the entities render much nicer when overlapping each other.
    {
        var blur_pass_query = ecs.query(.{
            c.Transform,
            c.NeonSprite,
        });
        while (blur_pass_query.next()) |item| {
            const transform: *c.Transform = item.get(c.Transform).?;
            const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;

            {
                const color_vec4: [4]f32 = a.colorToF32Array(neon_sprite.color);
                const drawParams = computeDrawParams(transform, neon_sprite);

                rl.beginShaderMode(shader.shader);
                rl.setShaderValue(shader.shader, shader.u_color, &color_vec4, .vec4);
                rl.drawTexturePro(
                    neon_sprite.atlas.texture,
                    neon_sprite.blur_texture_src,
                    drawParams.dest,
                    drawParams.origin,
                    drawParams.final_rotation_deg,
                    rl.Color.white,
                );
                rl.endShaderMode();
            }
        }
    }
    {
        var base_pass_query = ecs.query(.{
            c.Transform,
            c.NeonSprite,
        });
        while (base_pass_query.next()) |item| {
            const transform: *c.Transform = item.get(c.Transform).?;
            const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;

            const drawParams = computeDrawParams(transform, neon_sprite);

            rl.drawTexturePro(
                neon_sprite.atlas.texture,
                neon_sprite.base_texture_src,
                drawParams.dest,
                drawParams.origin,
                drawParams.final_rotation_deg,
                rl.Color.white,
            );
        }
    }
}

fn computeDrawParams(transform: *const c.Transform, sprite: *const c.NeonSprite) struct {
    dest: rl.Rectangle,
    origin: rl.Vector2,
    final_rotation_deg: f32,
} {
    const dest_width: f32 = sprite.base_texture_src.width * sprite.options.scale * transform.scale;
    const dest_height: f32 = sprite.base_texture_src.height * sprite.options.scale * transform.scale;
    const origin: rl.Vector2 = sprite.options.origin orelse .{ .x = dest_width / 2, .y = dest_height / 2 };
    const dest: rl.Rectangle = rl.Rectangle{
        .x = transform.pos.x,
        .y = transform.pos.y,
        .width = dest_width,
        .height = dest_height,
    };
    const final_rotation_deg = (transform.rotation_rad + sprite.options.rotation_rad) * math.RAD_TO_DEG;
    return .{
        .dest = dest,
        .origin = origin,
        .final_rotation_deg = final_rotation_deg,
    };
}
