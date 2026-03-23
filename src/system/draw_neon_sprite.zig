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

    rl.beginBlendMode(rl.BlendMode.additive);
    defer rl.endBlendMode();

    {
        var blur_pass_query = ecs.query(.{
            c.Transform,
            c.NeonSprite,
        });
        while (blur_pass_query.next()) |item| {
            const transform: *c.Transform = item.get(c.Transform).?;
            const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;

            const color_vec4: [4]f32 = a.colorToF32Array(neon_sprite.color);
            const src: rl.Rectangle = textureSource(
                neon_sprite.atlas,
                neon_sprite.sprite_index,
                true,
            );
            const drawParams = computeDrawParams(
                transform,
                neon_sprite,
                src,
            );

            rl.beginShaderMode(shader.shader);
            rl.setShaderValue(
                shader.shader,
                shader.u_color,
                &color_vec4,
                .vec4,
            );
            rl.drawTexturePro(
                neon_sprite.atlas.texture,
                src,
                drawParams.dest,
                drawParams.origin,
                drawParams.final_rotation_deg,
                rl.Color.white,
            );
            rl.endShaderMode();
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

            const src: rl.Rectangle = textureSource(
                neon_sprite.atlas,
                neon_sprite.sprite_index,
                false,
            );
            const drawParams = computeDrawParams(
                transform,
                neon_sprite,
                src,
            );

            rl.drawTexturePro(
                neon_sprite.atlas.texture,
                src,
                drawParams.dest,
                drawParams.origin,
                drawParams.final_rotation_deg,
                rl.Color.white,
            );
        }
    }
}

fn textureSource(atlas: a.TextureAtlas, sprite_index: usize, retrieve_blur: bool) rl.Rectangle {
    const cols_i32: i32 = @divFloor(atlas.texture.width, atlas.cell_width);
    const cols: usize = @as(usize, @intCast(cols_i32));
    const row: usize = sprite_index / cols;
    const col: usize = sprite_index % cols;

    const col_f32: f32 = @floatFromInt(col);
    const row_f32: f32 = @floatFromInt(row);
    const cell_width_f32: f32 = @floatFromInt(atlas.cell_width);
    const cell_height_f32: f32 = @floatFromInt(atlas.cell_height);

    var y: f32 = undefined;
    if (retrieve_blur) {
        y = row_f32 * 2.0 * cell_height_f32 + cell_height_f32;
    } else {
        y = row_f32 * 2.0 * cell_height_f32;
    }

    return rl.Rectangle{
        .x = col_f32 * cell_width_f32,
        .y = y,
        .width = cell_width_f32,
        .height = cell_height_f32,
    };
}

fn computeDrawParams(transform: *const c.Transform, neon_sprite: *const c.NeonSprite, src: rl.Rectangle) struct {
    dest: rl.Rectangle,
    origin: rl.Vector2,
    final_rotation_deg: f32,
} {
    const dest_width: f32 = src.width * neon_sprite.scale * transform.scale;
    const dest_height: f32 = src.height * neon_sprite.scale * transform.scale;
    const origin: rl.Vector2 = neon_sprite.origin orelse .{ .x = dest_width / 2, .y = dest_height / 2 };
    const dest: rl.Rectangle = rl.Rectangle{
        .x = transform.pos.x,
        .y = transform.pos.y,
        .width = dest_width,
        .height = dest_height,
    };
    const final_rotation_deg = (transform.rotation_rad + neon_sprite.rotation_rad) * math.RAD_TO_DEG;
    return .{
        .dest = dest,
        .origin = origin,
        .final_rotation_deg = final_rotation_deg,
    };
}
