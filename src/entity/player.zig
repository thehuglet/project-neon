const rl = @import("raylib");

pub const Player = struct {
    pos: rl.Vector2,
    facing_angle: f32,
    speed: f32,
    texture: rl.Texture,
};
