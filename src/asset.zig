const std = @import("std");

const rl = @import("raylib");

pub const TextureAtlas = struct {
    texture: rl.Texture2D,
    cell_width: i32,
    cell_height: i32,

    pub fn init(path: [:0]const u8, cell_width: i32, cell_height: i32) TextureAtlas {
        return .{
            .texture = rl.loadTexture(path) catch |err| {
                std.debug.panic("Error loading texture: {s}, (error: {})", .{ path, err });
            },
            .cell_width = cell_width,
            .cell_height = cell_height,
        };
    }

    pub fn deinit(self: TextureAtlas) void {
        deinitAtlas(self);
    }
};

pub fn deinitAtlas(atlas: TextureAtlas) void {
    rl.unloadTexture(atlas.texture);
}
