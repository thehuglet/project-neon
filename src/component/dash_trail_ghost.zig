pub const DashTrailGhost = struct {
    initial_lifetime_sec: f32,
    remaining_lifetime_sec: f32,
    original_alpha: u8,

    pub fn init(lifetime: f32, alpha: u8) DashTrailGhost {
        return DashTrailGhost{
            .initial_lifetime_sec = lifetime,
            .remaining_lifetime_sec = lifetime,
            .original_alpha = alpha,
        };
    }
};
