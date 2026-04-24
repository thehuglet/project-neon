const rl = @import("raylib");

pub const F32Range = struct {
    min: f32,
    max: f32,

    pub fn sample(self: F32Range, t: f32) f32 {
        return self.min + (self.max - self.min) * t;
    }

    pub fn toVec2(self: F32Range) rl.Vector2 {
        return rl.Vector2{ .x = self.min, .y = self.max };
    }
};

pub const F32FlatOrRange = union(enum) {
    flat: f32,
    range: F32Range,

    pub fn toF32Range(self: F32FlatOrRange) F32Range {
        return switch (self) {
            .flat => |s| .{ .min = s, .max = s },
            .range => |r| r,
        };
    }
};
