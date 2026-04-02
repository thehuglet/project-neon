pub const DashTrailGhost = struct {
    lifetime_sec: f32,
    remaining_lifetime_sec: f32,
    hue_shift_over_lifetime: f32 = 0.0,
    scale_over_lifetime: f32 = 0.0,

    current_alpha_scale: f32 = 1.0,
    current_hue_shift: f32 = 0.0,
    current_scale: f32 = 1.0,
};
