pub const NeonSprite = @import("neon_sprite.zig").NeonSprite;
pub const Player = @import("player.zig").Player;
pub const Transform = @import("transform.zig").Transform;
pub const Spin = @import("spin.zig").Spin;

/// Components registered here will be available in the ECS.
pub const Registry = [_]struct {
    T: type,
    field_name: [:0]const u8,
}{
    .{ .T = Player, .field_name = "player" },
    .{ .T = NeonSprite, .field_name = "neon_sprite" },
    .{ .T = Transform, .field_name = "transform" },
    .{ .T = Spin, .field_name = "spin" },
};
