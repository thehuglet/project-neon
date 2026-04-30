const enums = @import("enums");

pub const DeathParticles = struct {
    count: u32,
    texture: struct {
        atlas_id: enums.AtlasId,
        cell_index: usize,
    },
    extra_velocity_factor: f32 = 1.0,
    speed_factor: f32 = 1.0,
    scale_factor: f32 = 1.0,
};
