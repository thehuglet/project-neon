const std = @import("std");

const rl = @import("raylib");

pub const UniformError = error{
    InvalidUniform,
};

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
        rl.unloadTexture(self.texture);
    }
};

pub const NeonSpriteShader = struct {
    shader: rl.Shader,
    u_color: i32,

    pub fn init(path: [:0]const u8) NeonSpriteShader {
        const shader = rl.loadShader(null, path) catch |err| {
            std.debug.panic("Invalid shader path: {s} (error: {})", .{ path, err });
        };

        const neon_sprite = NeonSpriteShader{
            .shader = shader,
            .u_color = rl.getShaderLocation(shader, "u_color"),
        };

        verifyUniforms(&[_]i32{
            neon_sprite.u_color,
        });

        return neon_sprite;
    }

    pub fn deinit(self: NeonSpriteShader) void {
        rl.unloadShader(self.shader);
    }
};

pub const Assets = struct {
    cube_atlas: TextureAtlas,
    neon_sprite_shader: NeonSpriteShader,
};

pub fn colorToF32Array(color: rl.Color) [4]f32 {
    return .{
        @as(f32, @floatFromInt(color.r)) / 255.0,
        @as(f32, @floatFromInt(color.g)) / 255.0,
        @as(f32, @floatFromInt(color.b)) / 255.0,
        @as(f32, @floatFromInt(color.a)) / 255.0,
    };
}

fn verifyUniforms(uniforms: []const i32) void {
    for (uniforms) |u| {
        if (u == -1) {
            @panic("Unknown uniform definition.");
        }
    }
}
