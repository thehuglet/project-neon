pub const DamageFlash = struct {
    duration_sec: f32,
    remaining_duration_sec: f32,
    peak_lightness_shift: f32,
    peak_alpha_scale: f32,

    current_lightness_shift: f32 = 0.0,
    current_alpha_scale: f32 = 1.0,
};
