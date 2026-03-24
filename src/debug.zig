pub const rl = @import("raylib");

pub const DebugSettings = struct {
    show_hurtboxes: bool,
    show_hitboxes: bool,
};

pub fn handleDebugHotkeys(settings: *DebugSettings) void {
    // ------ Toggles ------
    if (rl.isKeyPressed(rl.KeyboardKey.b)) {
        settings.show_hurtboxes = !settings.show_hurtboxes;
    }
    if (rl.isKeyPressed(rl.KeyboardKey.n)) {
        settings.show_hitboxes = !settings.show_hitboxes;
    }
}
