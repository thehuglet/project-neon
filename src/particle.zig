const Context = @import("context").Context;

const std = @import("std");
const rl = @import("raylib");
const helpers = @import("helpers");

pub const ParticleData = struct {
    compute_shader: u32,
    ssbo_positions: u32,
    ssbo_velocities: u32,
};

pub fn init(allocator: std.mem.Allocator, rng: std.Random) ParticleData {
    const shader_code = rl.loadFileText("assets/shaders/particle_compute.glsl");
    const shader_data: u32 = rl.gl.rlCompileShader(shader_code, rl.gl.rl_compute_shader);
    const compute_shader = rl.gl.rlLoadComputeShaderProgram(shader_data);
    rl.unloadFileText(shader_code);

    const num_particles: u32 = 1024 * 256;

    const positions: []rl.Vector4 = allocator.alloc(rl.Vector4, num_particles) catch {
        @panic("OOM");
    };
    defer allocator.free(positions);

    const velocities: []rl.Vector4 = allocator.alloc(rl.Vector4, num_particles) catch {
        @panic("OOM");
    };
    defer allocator.free(velocities);

    for (0..num_particles) |i| {
        positions[i] = rl.Vector4{
            .x = helpers.randomFloatRange(rng, -0.5, 0.5),
            .y = helpers.randomFloatRange(rng, -0.5, 0.5),
            .z = 0.0,
            .w = 0.0,
        };
        velocities[i] = rl.Vector4.init(0.0, 0.0, 0.0, 0.0);
    }

    const ssbo_positions = rl.gl.rlLoadShaderBuffer(
        num_particles * @sizeOf(rl.Vector4),
        positions.ptr,
        rl.gl.rl_dynamic_copy,
    );
    const ssbo_velocities = rl.gl.rlLoadShaderBuffer(
        num_particles * @sizeOf(rl.Vector4),
        velocities.ptr,
        rl.gl.rl_dynamic_copy,
    );

    const vao: u32 = rl.gl.rlLoadVertexArray();
    _ = rl.gl.rlEnableVertexArray(vao);

    const vertices = [6]rl.Vector2{
        // A
        .init(-0.5, -0.5),
        .init(0.5, -0.5),
        .init(0.5, 0.5),
        // B
        .init(-0.5, -0.5),
        .init(0.5, 0.5),
        .init(-0.5, 0.5),
    };

    rl.gl.rlEnableVertexAttribute(0);
    _ = rl.gl.rlLoadVertexBuffer(&vertices, @sizeOf(@TypeOf(vertices)), false);
    rl.gl.rlSetVertexAttribute(0, 2, rl.gl.rl_float, false, 0, 0);
    rl.gl.rlDisableVertexArray();

    return ParticleData{
        .compute_shader = compute_shader,
        .ssbo_positions = ssbo_positions,
        .ssbo_velocities = ssbo_velocities,
    };
}

// pub fn deinit(data: ParticleData) void {}

// pub fn compute(ctx: *Context) void {
//     rl.gl.rlEnableShader(ctx.particles.compute_shader);
//     rl.gl.rlSetUniform(0, &deltaTime, SHADER_UNIFORM_FLOAT, 1);
//     rlSetUniform(1, &speed, SHADER_UNIFORM_FLOAT, 1);
//     rlBindShaderBuffer(ssboPositions, 0);
//     rlBindShaderBuffer(ssboVelocities, 1);
//     rlComputeShaderDispatch(numParticles / 1024, 1, 1);
//     rlDisableShader();
// }
