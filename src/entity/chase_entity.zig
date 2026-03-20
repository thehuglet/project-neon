const rl = @import("raylib");

const math = @import("math");

pub const ChaseEntity = struct {
    entity_id: usize,
    /// Has to be a normalized Vector2
    facing_direction: rl.Vector2 = math.VECTOR2_ZERO,
};
