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

        const wrapper = NeonSpriteShader{
            .shader = shader,
            .u_color = rl.getShaderLocation(shader, "u_color"),
        };

        verifyUniforms(&[_]i32{
            wrapper.u_color,
        });

        return wrapper;
    }

    pub fn deinit(self: NeonSpriteShader) void {
        rl.unloadShader(self.shader);
    }
};

pub const BloomShader = struct {
    shader: rl.Shader,

    pub fn init(path: [:0]const u8) BloomShader {
        const shader = rl.loadShader(null, path) catch |err| {
            std.debug.panic("Invalid shader path: {s} (error: {})", .{ path, err });
        };

        const wrapper = BloomShader{
            .shader = shader,
        };

        return wrapper;
    }

    pub fn deinit(self: BloomShader) void {
        rl.unloadShader(self.shader);
    }
};

pub const BackgroundShader = struct {
    shader: rl.Shader,
    u_resolution: i32,
    u_time: i32,

    pub fn init(path: [:0]const u8) BackgroundShader {
        const shader = rl.loadShader(null, path) catch |err| {
            std.debug.panic("Invalid shader path: {s} (error: {})", .{ path, err });
        };

        const wrapper = BackgroundShader{
            .shader = shader,
            .u_resolution = rl.getShaderLocation(shader, "u_resolution"),
            .u_time = rl.getShaderLocation(shader, "u_time"),
        };

        verifyUniforms(&[_]i32{
            wrapper.u_resolution,
            wrapper.u_time,
        });

        return wrapper;
    }

    pub fn deinit(self: BackgroundShader) void {
        rl.unloadShader(self.shader);
    }
};

pub const Assets = struct {
    cube_atlas: TextureAtlas,
    roto_atlas: TextureAtlas,
    neon_sprite_shader: NeonSpriteShader,
    bloom_shader: BloomShader,
    background_shader: BackgroundShader,
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
