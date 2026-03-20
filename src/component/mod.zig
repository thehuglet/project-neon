pub const NeonSprite = @import("neon_sprite.zig").NeonSprite;
pub const Player = @import("player.zig").Player;
pub const Transform = @import("transform.zig").Transform;
pub const SpinCosmetic = @import("spin_cosmetic.zig").SpinCosmetic;
pub const ChaseEntity = @import("chase_entity.zig").ChaseEntity;
pub const MovementSpeed = @import("movement_speed.zig").MovementSpeed;
pub const DynamicMovementSpeed = @import("dynamic_movement_speed.zig").DynamicMovementSpeed;

/// Components registered here will be available in the ECS.
pub const Registry = [_]struct {
    T: type,
    field_name: [:0]const u8,
}{
    .{ .T = Player, .field_name = "player" },
    .{ .T = NeonSprite, .field_name = "neon_sprite" },
    .{ .T = Transform, .field_name = "transform" },
    .{ .T = SpinCosmetic, .field_name = "spin_cosmetic" },
    .{ .T = ChaseEntity, .field_name = "chase_entity" },
    .{ .T = MovementSpeed, .field_name = "movement_speed" },
    .{ .T = DynamicMovementSpeed, .field_name = "dynamic_movement_speed" },
};
