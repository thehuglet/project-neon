const Context = @import("context").Context;

const std = @import("std");
const rl = @import("raylib");
const c = @import("component");
const TextureAtlas = @import("context").TextureAtlas;

const math = @import("math");
const helpers = @import("helpers");

pub fn drawNeonSprites(ctx: *Context) void {
    rl.beginBlendMode(rl.BlendMode.additive);
    defer rl.endBlendMode();

    // Blur sprite drawing
    {
        const shader = ctx.shaders.get(.neon_sprite).?;
        rl.beginShaderMode(shader);
        defer rl.endShaderMode();

        var blur_pass_query = ctx.ecs.query(.{
            c.Transform,
            c.NeonSprite,
        });
        while (blur_pass_query.next()) |item| {
            const transform: *c.Transform = item.get(c.Transform).?;
            const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;

            var alpha: f32 = @as(f32, @floatFromInt(neon_sprite.color.a)) / 255.0;
            var alpha_scale: f32 = 1.0;
            var scale: f32 = neon_sprite.scale;
            var hue_shift: f32 = 0.0;
            var lightness_shift: f32 = 0.0;

            // --- Component-based alterations
            if (ctx.ecs.getComponent(item.entity_id, c.DashTrailGhost)) |ghost| {
                alpha *= ghost.current_alpha_scale;
                scale *= ghost.current_scale;
                hue_shift += ghost.current_hue_shift;
            }
            if (ctx.ecs.getComponent(item.entity_id, c.DamageFlash)) |dmg_flash| {
                lightness_shift += dmg_flash.current_lightness_shift;
                alpha_scale *= dmg_flash.current_alpha_scale;
            }

            const src: rl.Rectangle = textureSource(
                neon_sprite.atlas,
                neon_sprite.sprite_index,
                true,
            );
            const draw_params = computeDrawParams(
                transform,
                neon_sprite,
                src,
                scale,
            );

            drawTextureNeonSprite(
                neon_sprite.atlas.texture,
                src,
                draw_params.dest,
                draw_params.origin,
                draw_params.final_rotation_deg,
                neon_sprite.color.alpha(alpha),
                hue_shift,
                lightness_shift,
                alpha_scale,
            );
        }
    }
    // Normal sprite drawing
    {
        var base_pass_query = ctx.ecs.query(.{
            c.Transform,
            c.NeonSprite,
        });
        while (base_pass_query.next()) |item| {
            const transform: *c.Transform = item.get(c.Transform).?;
            const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;

            var alpha: f32 = @as(f32, @floatFromInt(neon_sprite.color.a)) / 255.0;
            var scale: f32 = neon_sprite.scale;
            // var hue_shift: f32 = 0.0;

            // --- Component-based alterations
            if (ctx.ecs.getComponent(item.entity_id, c.DashTrailGhost)) |ghost| {
                alpha *= ghost.current_alpha_scale;
                scale *= ghost.current_scale;
                // hue_shift += ghost.current_hue_shift;
            }

            const src: rl.Rectangle = textureSource(
                neon_sprite.atlas,
                neon_sprite.sprite_index,
                false,
            );
            const draw_params = computeDrawParams(
                transform,
                neon_sprite,
                src,
                scale,
            );

            var tint_color: rl.Color = undefined;
            if (neon_sprite.tint_base) {
                tint_color = neon_sprite.color.alpha(alpha);
            } else {
                tint_color = rl.Color.init(255, 255, 255, @intFromFloat(
                    std.math.clamp(alpha * 255.0, 0.0, 255.0),
                ));
            }

            rl.drawTexturePro(
                neon_sprite.atlas.texture,
                src,
                draw_params.dest,
                draw_params.origin,
                draw_params.final_rotation_deg,
                tint_color,
            );
        }
    }
}

fn textureSource(atlas: TextureAtlas, sprite_index: usize, use_blur: bool) rl.Rectangle {
    const cols_i32: i32 = @divFloor(atlas.texture.width, atlas.cell_width);
    const cols: usize = @as(usize, @intCast(cols_i32));
    const row: usize = sprite_index / cols;
    const col: usize = sprite_index % cols;

    const col_f32: f32 = @floatFromInt(col);
    const row_f32: f32 = @floatFromInt(row);
    const cell_width_f32: f32 = @floatFromInt(atlas.cell_width);
    const cell_height_f32: f32 = @floatFromInt(atlas.cell_height);

    var y: f32 = undefined;
    if (use_blur) {
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

fn computeDrawParams(
    transform: *const c.Transform,
    neon_sprite: *const c.NeonSprite,
    src: rl.Rectangle,
    scale: f32,
) struct {
    dest: rl.Rectangle,
    origin: rl.Vector2,
    final_rotation_deg: f32,
} {
    const dest_width: f32 = src.width * transform.scale * scale;
    const dest_height: f32 = src.height * transform.scale * scale;
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

fn drawTextureNeonSprite(
    texture: rl.Texture,
    src: rl.Rectangle,
    dest: rl.Rectangle,
    origin: rl.Vector2,
    rotation_deg: f32,
    tint: rl.Color,
    hue_shift: f32,
    lightness_shift: f32,
    alpha_scale: f32,
) void {
    const width: f32 = @floatFromInt(texture.width);
    const height: f32 = @floatFromInt(texture.height);

    const rotation_rad = rotation_deg * math.DEG_TO_RAD;

    var flip_x = false;
    var src_local = src;

    if (src_local.width < 0) {
        flip_x = true;
        src_local.width *= -1;
    }
    if (src_local.height < 0) {
        src_local.y -= src_local.height;
    }

    const dest_w = @abs(dest.width);
    const dest_h = @abs(dest.height);

    const x = dest.x;
    const y = dest.y;

    var top_left: rl.Vector2 = undefined;
    var top_right: rl.Vector2 = undefined;
    var bottom_left: rl.Vector2 = undefined;
    var bottom_right: rl.Vector2 = undefined;

    if (rotation_rad == 0.0) {
        const ox = x - origin.x;
        const oy = y - origin.y;

        top_left = .{ .x = ox, .y = oy };
        top_right = .{ .x = ox + dest_w, .y = oy };
        bottom_left = .{ .x = ox, .y = oy + dest_h };
        bottom_right = .{ .x = ox + dest_w, .y = oy + dest_h };
    } else {
        const sin_r = @sin(rotation_rad);
        const cos_r = @cos(rotation_rad);

        const dx = -origin.x;
        const dy = -origin.y;

        top_left = .{
            .x = x + dx * cos_r - dy * sin_r,
            .y = y + dx * sin_r + dy * cos_r,
        };

        top_right = .{
            .x = x + (dx + dest_w) * cos_r - dy * sin_r,
            .y = y + (dx + dest_w) * sin_r + dy * cos_r,
        };

        bottom_left = .{
            .x = x + dx * cos_r - (dy + dest_h) * sin_r,
            .y = y + dx * sin_r + (dy + dest_h) * cos_r,
        };

        bottom_right = .{
            .x = x + (dx + dest_w) * cos_r - (dy + dest_h) * sin_r,
            .y = y + (dx + dest_w) * sin_r + (dy + dest_h) * cos_r,
        };
    }

    rl.gl.rlSetTexture(texture.id);
    rl.gl.rlBegin(rl.gl.rl_quads);

    rl.gl.rlColor4ub(tint.r, tint.g, tint.b, tint.a);
    rl.gl.rlNormal3f(hue_shift, lightness_shift, alpha_scale);

    // Top-left
    rl.gl.rlTexCoord2f(
        if (flip_x) (src_local.x + src_local.width) / width else src_local.x / width,
        src_local.y / height,
    );
    rl.gl.rlVertex2f(top_left.x, top_left.y);

    // Bottom-left
    rl.gl.rlTexCoord2f(
        if (flip_x) (src_local.x + src_local.width) / width else src_local.x / width,
        (src_local.y + src_local.height) / height,
    );
    rl.gl.rlVertex2f(bottom_left.x, bottom_left.y);

    // Bottom-right
    rl.gl.rlTexCoord2f(
        if (flip_x) src_local.x / width else (src_local.x + src_local.width) / width,
        (src_local.y + src_local.height) / height,
    );
    rl.gl.rlVertex2f(bottom_right.x, bottom_right.y);

    // Top-right
    rl.gl.rlTexCoord2f(
        if (flip_x) src_local.x / width else (src_local.x + src_local.width) / width,
        src_local.y / height,
    );
    rl.gl.rlVertex2f(top_right.x, top_right.y);

    rl.gl.rlEnd();
    rl.gl.rlSetTexture(0);
}
