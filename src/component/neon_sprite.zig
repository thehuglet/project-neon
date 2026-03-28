const rl = @import("raylib");

const TextureAtlas = @import("asset").TextureAtlas;

pub const NeonSprite = struct {
    atlas: TextureAtlas,
    sprite_index: usize,
    color: rl.Color,
    rotation_rad: f32 = 0.0,
    scale: f32 = 1.0,
    origin: ?rl.Vector2 = null,
    tint_base: bool = false,
};
