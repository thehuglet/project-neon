pub const NeonSprite = @import("neon_sprite.zig").NeonSprite;
pub const Player = @import("player.zig").Player;
pub const PlayerMovement = @import("player_movement.zig").PlayerMovement;
pub const Transform = @import("transform.zig").Transform;

/// Components registered here will be supported by the ECS.
pub const Registry = [_]struct {
    T: type,
    field_name: [:0]const u8,
}{
    .{ .T = Player, .field_name = "player" },
    .{ .T = PlayerMovement, .field_name = "player_movement" },
    .{ .T = NeonSprite, .field_name = "neon_sprite" },
    .{ .T = Transform, .field_name = "transform" },
};
