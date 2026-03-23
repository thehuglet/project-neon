// Markers
pub const Player = @import("player.zig").Player;
pub const TargetsPlayer = @import("targets_player.zig").TargetsPlayer;
pub const SpriteSwitcher = @import("sprite_switcher.zig").SpriteSwitcher;

// Other
pub const Motion = @import("motion.zig").Motion;
pub const Hitbox = @import("hitbox.zig").Hitbox;
pub const Hurtbox = @import("hurtbox.zig").Hurtbox;
pub const Movement = @import("movement.zig").Movement;
pub const Transform = @import("transform.zig").Transform;
pub const NeonSprite = @import("neon_sprite.zig").NeonSprite;
pub const ChaseEntity = @import("chase_entity.zig").ChaseEntity;
pub const SpinCosmetic = @import("spin_cosmetic.zig").SpinCosmetic;
pub const TargetedEntity = @import("targeted_entity.zig").TargetedEntity;

/// Components registered here will be available in the ECS.
pub const Registry = [_]struct {
    T: type,
    field_name: [:0]const u8,
}{
    // Markers
    .{ .T = Player, .field_name = "player" },
    .{ .T = TargetsPlayer, .field_name = "targets_player" },
    .{ .T = SpriteSwitcher, .field_name = "sprite_switcher" },

    // Other
    .{ .T = Motion, .field_name = "motion" },
    .{ .T = Hitbox, .field_name = "hitbox" },
    .{ .T = Hurtbox, .field_name = "hurtbox" },
    .{ .T = Movement, .field_name = "movement" },
    .{ .T = Transform, .field_name = "transform" },
    .{ .T = NeonSprite, .field_name = "neon_sprite" },
    .{ .T = ChaseEntity, .field_name = "chase_entity" },
    .{ .T = SpinCosmetic, .field_name = "spin_cosmetic" },
    .{ .T = TargetedEntity, .field_name = "targeted_entity" },
};

pub const CollisionLayer = struct {
    pub const player = 1 << 0;
    pub const enemy = 1 << 1;
    pub const neutral = 1 << 3;
    // pub const PROJECTILE_ENEMY = 1 << 4;
};
