const Context = @import("context").Context;

const std = @import("std");
const rl = @import("raylib");
const helpers = @import("helpers");
const c = @import("c").c;

pub const ParticleData = struct {
    vao: u32,
    num_particles: u32,
    compute_shader: u32,
    ssbo_0: u32,
    ssbo_1: u32,
};

pub fn init(allocator: std.mem.Allocator, rng: std.Random) ParticleData {
    const shader_code = rl.loadFileText("assets/shaders/particle_compute.glsl");
    const shader_data: u32 = rl.gl.rlCompileShader(shader_code, rl.gl.rl_compute_shader);
    const compute_shader = rl.gl.rlLoadComputeShaderProgram(shader_data);
    rl.unloadFileText(shader_code);

    const num_particles: u32 = 1024;

    const ssbo_0_data: []rl.Vector4 = allocator.alloc(rl.Vector4, num_particles) catch @panic("OOM");
    defer allocator.free(ssbo_0_data);

    const ssbo_1_data: []rl.Vector4 = allocator.alloc(rl.Vector4, num_particles) catch @panic("OOM");
    defer allocator.free(ssbo_1_data);

    for (0..num_particles - 1) |i| {
        const x_pos: f32 = helpers.randomFloatRange(rng, -1.0, 1.0);
        const y_pos: f32 = helpers.randomFloatRange(rng, -1.0, 1.0);
        const lifetime_sec: f32 = helpers.randomFloatRange(rng, 2.0, 15.0);

        ssbo_0_data[i] = rl.Vector4.init(
            x_pos,
            y_pos,
            lifetime_sec,
            0.0,
        );
        ssbo_1_data[i] = rl.Vector4.init(
            0.0,
            0.0,
            0.0,
            0.0,
        );
    }

    const ssbo_0 = rl.gl.rlLoadShaderBuffer(
        num_particles * @sizeOf(rl.Vector4),
        ssbo_0_data.ptr,
        rl.gl.rl_dynamic_copy,
    );
    const ssbo_1 = rl.gl.rlLoadShaderBuffer(
        num_particles * @sizeOf(rl.Vector4),
        ssbo_1_data.ptr,
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
        .vao = vao,
        .num_particles = num_particles,
        .compute_shader = compute_shader,
        .ssbo_0 = ssbo_0,
        .ssbo_1 = ssbo_1,
    };
}

pub fn deinit(data: ParticleData) void {
    rl.gl.rlUnloadShaderBuffer(data.ssbo_0);
    rl.gl.rlUnloadShaderBuffer(data.ssbo_1);
    rl.gl.rlUnloadVertexArray(data.vao);
    rl.gl.rlUnloadShaderProgram(data.compute_shader);
}

pub fn compute(data: *ParticleData) void {
    const dt: f32 = rl.getFrameTime();
    const speed: f32 = 1.0;

    helpers.assertUniformLoc(data.compute_shader, "deltaTime", 0);
    helpers.assertUniformLoc(data.compute_shader, "speed", 1);

    rl.gl.rlEnableShader(data.compute_shader);
    rl.gl.rlSetUniform(0, &dt, @intFromEnum(rl.ShaderUniformDataType.float), 1);
    rl.gl.rlSetUniform(1, &speed, @intFromEnum(rl.ShaderUniformDataType.float), 1);
    rl.gl.rlBindShaderBuffer(data.ssbo_0, 0);
    rl.gl.rlBindShaderBuffer(data.ssbo_1, 1);
    rl.gl.rlComputeShaderDispatch(data.num_particles / 1024, 1, 1);
    rl.gl.rlDisableShader();
}

pub fn draw(ctx: *Context) void {
    const shader = ctx.shaders.get(.particle).?;
    const particle_scale: f32 = 1.0;

    helpers.assertUniformLoc(shader.id, "particleScale", 0);

    rl.beginShaderMode(shader);
    rl.setShaderValue(shader, 0, &particle_scale, rl.ShaderUniformDataType.float);

    rl.gl.rlBindShaderBuffer(ctx.particle_data.ssbo_0, 0);
    rl.gl.rlBindShaderBuffer(ctx.particle_data.ssbo_1, 1);

    _ = rl.gl.rlEnableVertexArray(ctx.particle_data.vao);
    rl.gl.rlDrawVertexArrayInstanced(0, 6, @intCast(ctx.particle_data.num_particles));
    rl.gl.rlDisableVertexArray();
    rl.endShaderMode();
}
