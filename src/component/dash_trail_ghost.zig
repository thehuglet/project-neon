pub const DashTrailGhost = struct {
    initial_lifetime_sec: f32,
    remaining_lifetime_sec: f32,
    original_alpha: u8,
    original_scale: f32,
    hue_shift_over_lifetime: f32 = 0.0,
    scale_over_lifetime: f32 = 0.0,
};
