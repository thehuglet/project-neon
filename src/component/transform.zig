const rl = @import("raylib");

pub const Transform = struct {
    pos: rl.Vector2,
    rotation_rad: f32,
    scale: f32,
};
