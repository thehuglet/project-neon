pub const RingOverT = struct {
    radius: f32,
    /// [0.0..1.0]
    t: f32,
    /// [0.0..1.0]
    max_radius_at_t: f32,
    /// [0.0..1.0]
    fade_in_at_t: f32,
    /// [0.0..1.0]
    fade_out_at_t: f32,
};
