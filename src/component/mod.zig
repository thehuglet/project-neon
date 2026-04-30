// Markers
pub const Player = @import("player.zig").Player;
pub const TargetsPlayer = @import("targets_player.zig").TargetsPlayer;
pub const DespawnsWhenOOB = @import("despawns_when_oob.zig").DespawnsWhenOOB;
pub const OneTickHitbox = @import("one_tick_hitbox.zig").OneTickHitbox;
pub const Dead = @import("dead.zig").Dead;

// Health
pub const Health = @import("health.zig").Health;
pub const HealthLives = @import("health_lives.zig").HealthLives;

// Collisions
pub const Hitbox = @import("hitbox.zig").Hitbox;
pub const Hurtbox = @import("hurtbox.zig").Hurtbox;
pub const HitHistory = @import("hit_history.zig").HitHistory;

// Visual
pub const NeonSprite = @import("neon_sprite.zig").NeonSprite;
pub const SpinCosmetic = @import("spin_cosmetic.zig").SpinCosmetic;
pub const SpinCosmeticAccelScaled = @import("spin_cosmetic_accel_scaled.zig").SpinCosmeticAccelScaled;
pub const DashTrailGhost = @import("dash_trail_ghost.zig").DashTrailGhost;
pub const DamageFlash = @import("damage_flash.zig").DamageFlash;
pub const RingOverT = @import("ring_over_t.zig").RingOverT;
pub const DeathParticles = @import("death_particles.zig").DeathParticles;

// Other
pub const Transform = @import("transform.zig").Transform;
pub const Movement = @import("movement.zig").Movement;
pub const Motion = @import("motion.zig").Motion;
pub const Dashing = @import("dashing.zig").Dashing;
pub const ChaseEntity = @import("chase_entity.zig").ChaseEntity;
pub const TargetedEntity = @import("targeted_entity.zig").TargetedEntity;
pub const WeaponUseIntent = @import("weapon_use_intent.zig").WeaponUseIntent;
pub const WeaponSlots = @import("weapon_slots.zig").WeaponSlots;
pub const Lumen = @import("lumen.zig").Lumen;
pub const Owner = @import("owner.zig").Owner;
pub const ProjectileWeaponsStats = @import("projectile_weapons_stats.zig").ProjectileWeaponsStats;
pub const GeneratesLumen = @import("generates_lumen.zig").GeneratesLumen;
pub const OnDeath = @import("on_death.zig").OnDeath;
pub const Lifetime = @import("lifetime.zig").Lifetime;

pub const Registry = [_]type{
    Player,
    TargetsPlayer,
    DespawnsWhenOOB,
    OneTickHitbox,
    Dead,

    // Health
    Health,
    HealthLives,

    // Collisions
    Hitbox,
    Hurtbox,
    HitHistory,

    // Visual
    NeonSprite,
    SpinCosmetic,
    SpinCosmeticAccelScaled,
    DashTrailGhost,
    DamageFlash,
    RingOverT,
    DeathParticles,

    // Other
    Transform,
    Movement,
    Motion,
    Dashing,
    ChaseEntity,
    TargetedEntity,
    WeaponUseIntent,
    WeaponSlots,
    Lumen,
    Owner,
    ProjectileWeaponsStats,
    GeneratesLumen,
    OnDeath,
    Lifetime,
};
