// Markers
pub const Player = @import("player.zig").Player;
pub const TargetsPlayer = @import("targets_player.zig").TargetsPlayer;

// Health
pub const Health = @import("health.zig").Health;
pub const HealthLives = @import("health_lives.zig").HealthLives;

// Collisions
pub const Hitbox = @import("hitbox.zig").Hitbox;
pub const Hurtbox = @import("hurtbox.zig").Hurtbox;

// Visual
pub const NeonSprite = @import("neon_sprite.zig").NeonSprite;
pub const SpinCosmetic = @import("spin_cosmetic.zig").SpinCosmetic;

// Other
pub const Transform = @import("transform.zig").Transform;
pub const Movement = @import("movement.zig").Movement;
pub const Motion = @import("motion.zig").Motion;
pub const ChaseEntity = @import("chase_entity.zig").ChaseEntity;
pub const TargetedEntity = @import("targeted_entity.zig").TargetedEntity;

// Debug
pub const SpriteSwitcher = @import("sprite_switcher.zig").SpriteSwitcher;

/// Components registered here will be available in the ECS.
pub const Registry = [_]struct {
    T: type,
    field_name: [:0]const u8,
}{
    // Markers
    .{ .T = Player, .field_name = "player" },
    .{ .T = TargetsPlayer, .field_name = "targets_player" },

    // Health
    .{ .T = Health, .field_name = "health" },
    .{ .T = HealthLives, .field_name = "health_lives" },

    // Collision
    .{ .T = Hitbox, .field_name = "hitbox" },
    .{ .T = Hurtbox, .field_name = "hurtbox" },

    // Visual
    .{ .T = NeonSprite, .field_name = "neon_sprite" },
    .{ .T = SpinCosmetic, .field_name = "spin_cosmetic" },

    // Other
    .{ .T = Transform, .field_name = "transform" },
    .{ .T = Movement, .field_name = "movement" },
    .{ .T = Motion, .field_name = "motion" },
    .{ .T = TargetedEntity, .field_name = "targeted_entity" },
    .{ .T = ChaseEntity, .field_name = "chase_entity" },

    // Debug
    .{ .T = SpriteSwitcher, .field_name = "sprite_switcher" },
};

pub const CollisionLayer = struct {
    pub const player = 1 << 0;
    pub const enemy = 1 << 1;
};
