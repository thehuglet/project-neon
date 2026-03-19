const rl = @import("raylib");

const TextureAtlas = @import("asset").TextureAtlas;

pub const NeonSprite = struct {
    pub const Options = struct {
        rotation_rad: f32 = 0.0,
        scale: f32 = 1.0,
        origin: ?rl.Vector2 = null,
    };

    atlas: TextureAtlas,
    base_texture_src: rl.Rectangle,
    blur_texture_src: rl.Rectangle,
    color: rl.Color,
    options: Options,

    pub fn init(
        atlas: TextureAtlas,
        sprite_index: usize,
        color: rl.Color,
        options: Options,
    ) NeonSprite {
        const cols_i32: i32 = @divFloor(atlas.texture.width, atlas.cell_width);
        const cols: usize = @as(usize, @intCast(cols_i32));
        const row: usize = sprite_index / cols;
        const col: usize = sprite_index % cols;

        const col_f32: f32 = @floatFromInt(col);
        const row_f32: f32 = @floatFromInt(row);
        const cell_width_f32: f32 = @floatFromInt(atlas.cell_width);
        const cell_height_f32: f32 = @floatFromInt(atlas.cell_height);

        const base_src = rl.Rectangle{
            .x = col_f32 * cell_width_f32,
            .y = row_f32 * 2.0 * cell_height_f32,
            .width = cell_width_f32,
            .height = cell_height_f32,
        };
        const blur_src = rl.Rectangle{
            .x = col_f32 * cell_width_f32,
            .y = row_f32 * 2.0 * cell_height_f32 + cell_height_f32,
            .width = cell_width_f32,
            .height = cell_height_f32,
        };

        return .{
            .atlas = atlas,
            .base_texture_src = base_src,
            .blur_texture_src = blur_src,
            .color = color,
            .options = options,
        };
    }
};
