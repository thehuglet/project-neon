// Markers
pub const Player = @import("player.zig").Player;
pub const TargetsPlayer = @import("targets_player.zig").TargetsPlayer;
pub const DespawnsWhenOOB = @import("despawns_when_oob.zig").DespawnsWhenOOB;

// Health
pub const Health = @import("health.zig").Health;
pub const HealthLives = @import("health_lives.zig").HealthLives;

// Collisions
pub const Hitbox = @import("hitbox.zig").Hitbox;
pub const Hurtbox = @import("hurtbox.zig").Hurtbox;

// Visual
pub const NeonSprite = @import("neon_sprite.zig").NeonSprite;
pub const SpinCosmetic = @import("spin_cosmetic.zig").SpinCosmetic;
pub const SpinCosmeticAccelScaled = @import("spin_cosmetic_accel_scaled.zig").SpinCosmeticAccelScaled;
pub const DashTrailGhost = @import("dash_trail_ghost.zig").DashTrailGhost;

// Other
pub const PlayerInput = @import("player_input.zig").PlayerInput;
pub const Transform = @import("transform.zig").Transform;
pub const Movement = @import("movement.zig").Movement;
pub const Motion = @import("motion.zig").Motion;
pub const Dashing = @import("dashing.zig").Dashing;
pub const ChaseEntity = @import("chase_entity.zig").ChaseEntity;
pub const TargetedEntity = @import("targeted_entity.zig").TargetedEntity;
pub const WeaponUseIntent = @import("weapon_use_intent.zig").WeaponUseIntent;
pub const WeaponSlots = @import("weapon_slots.zig").WeaponSlots;

/// Components registered here will be available in the ECS.
pub const Registry = [_]struct {
    component_type: type,
    field_name: [:0]const u8,
}{
    // Markers
    .{ .component_type = Player, .field_name = "player" },
    .{ .component_type = TargetsPlayer, .field_name = "targets_player" },
    .{ .component_type = DespawnsWhenOOB, .field_name = "despawns_when_oob" },

    // Health
    .{ .component_type = Health, .field_name = "health" },
    .{ .component_type = HealthLives, .field_name = "health_lives" },

    // Collision
    .{ .component_type = Hitbox, .field_name = "hitbox" },
    .{ .component_type = Hurtbox, .field_name = "hurtbox" },

    // Visual
    .{ .component_type = NeonSprite, .field_name = "neon_sprite" },
    .{ .component_type = SpinCosmetic, .field_name = "spin_cosmetic" },
    .{ .component_type = SpinCosmeticAccelScaled, .field_name = "spin_cosmetic_accel_scaled" },
    .{ .component_type = DashTrailGhost, .field_name = "dash_trail_ghost" },

    // Other
    .{ .component_type = PlayerInput, .field_name = "player_input" },
    .{ .component_type = Transform, .field_name = "transform" },
    .{ .component_type = Movement, .field_name = "movement" },
    .{ .component_type = Motion, .field_name = "motion" },
    .{ .component_type = Dashing, .field_name = "dashing" },
    .{ .component_type = TargetedEntity, .field_name = "targeted_entity" },
    .{ .component_type = ChaseEntity, .field_name = "chase_entity" },
    .{ .component_type = WeaponSlots, .field_name = "weapon_slots" },
    .{ .component_type = WeaponUseIntent, .field_name = "weapon_use_intent" },
};

pub const CollisionLayer = struct {
    pub const player = 1 << 0;
    pub const enemy = 1 << 1;
};
