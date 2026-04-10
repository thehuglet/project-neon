const CollisionLayer = @import("context").CollisionLayer;

pub const Hitbox = struct {
    radius: f32,
    mask: CollisionLayer,
    damage: f32,
    active: bool = true,
};
