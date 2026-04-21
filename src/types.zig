const rl = @import("raylib");

pub const Range = struct {
    min: f32,
    max: f32,

    pub fn sample(self: Range, t: f32) f32 {
        return self.min + (self.max - self.min) * t;
    }

    pub fn toVec2(self: Range) rl.Vector2 {
        return rl.Vector2{ .x = self.min, .y = self.max };
    }
};
