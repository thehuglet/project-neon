const CollisionLayer = @import("context").CollisionLayer;

pub const Hurtbox = struct {
    radius: f32,
    layer: CollisionLayer,
};
