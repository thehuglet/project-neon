const Context = @import("context").Context;

const std = @import("std");
const rl = @import("raylib");
const helpers = @import("helpers");

pub const ParticleData = struct {
    vao: u32,
    max_particles: u32,
    alive_count: u32,
    compute_shader: u32,
    post_compute_shader: u32,
    ssbo_0_set_0: u32,
    ssbo_1_set_0: u32,
    ssbo_0_set_1: u32,
    ssbo_1_set_1: u32,
    atomic_counter: u32,
    indirect_buffer: u32,
    current_set: u8,
};

pub fn init(allocator: std.mem.Allocator, rng: std.Random) ParticleData {
    const compute_shader: u32 = blk: {
        const shader_code: [:0]u8 = rl.loadFileText("assets/shaders/particle_compute.glsl");
        const shader_id: u32 = rl.gl.rlLoadShader(shader_code, rl.gl.rl_compute_shader);
        rl.unloadFileText(shader_code);
        break :blk shader_id;
    };

    const post_compute_shader: u32 = blk: {
        const shader_code: [:0]u8 = rl.loadFileText("assets/shaders/particle_post_compute.glsl");
        const shader_id: u32 = rl.gl.rlLoadShader(shader_code, rl.gl.rl_compute_shader);
        rl.unloadFileText(shader_code);
        break :blk shader_id;
    };

    const max_particles: u32 = 1024;

    const ssbo_0_data: []rl.Vector4 = allocator.alloc(rl.Vector4, max_particles) catch @panic("OOM");
    defer allocator.free(ssbo_0_data);

    const ssbo_1_data: []rl.Vector4 = allocator.alloc(rl.Vector4, max_particles) catch @panic("OOM");
    defer allocator.free(ssbo_1_data);

    for (0..max_particles - 1) |i| {
        const x_pos: f32 = helpers.randomFloatRange(rng, -1.0, 1.0);
        const y_pos: f32 = helpers.randomFloatRange(rng, -1.0, 1.0);
        const lifetime_sec: f32 = helpers.randomFloatRange(rng, 2.0, 15.0);

        ssbo_0_data[i] = rl.Vector4.init(x_pos, y_pos, lifetime_sec, 0.0);
        ssbo_1_data[i] = rl.Vector4.init(0.0, 0.0, 0.0, 0.0);
    }

    const ssbo_0_set_0 = rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), ssbo_0_data.ptr, rl.gl.rl_dynamic_copy);
    const ssbo_1_set_0 = rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), ssbo_1_data.ptr, rl.gl.rl_dynamic_copy);
    const ssbo_0_set_1 = rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), ssbo_0_data.ptr, rl.gl.rl_dynamic_copy);
    const ssbo_1_set_1 = rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), ssbo_1_data.ptr, rl.gl.rl_dynamic_copy);

    const zero: u32 = 0;
    const atomic_counter = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &zero, rl.gl.rl_dynamic_copy);

    const initial_groups = (max_particles + 1023) / 1024;
    const indirect_data = [_]u32{ initial_groups, 1, 1 };
    const indirect_buffer = rl.gl.rlLoadShaderBuffer(3 * @sizeOf(u32), &indirect_data, rl.gl.rl_dynamic_copy);

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
        .max_particles = max_particles,
        .alive_count = max_particles,
        .compute_shader = compute_shader,
        .post_compute_shader = post_compute_shader,
        .ssbo_0_set_0 = ssbo_0_set_0,
        .ssbo_1_set_0 = ssbo_1_set_0,
        .ssbo_0_set_1 = ssbo_0_set_1,
        .ssbo_1_set_1 = ssbo_1_set_1,
        .atomic_counter = atomic_counter,
        .indirect_buffer = indirect_buffer,
        .current_set = 0,
    };
}

pub fn deinit(data: ParticleData) void {
    rl.gl.rlUnloadShaderBuffer(data.current_ssbo_0);
    rl.gl.rlUnloadShaderBuffer(data.current_ssbo_1);
    rl.gl.rlUnloadVertexArray(data.vao);
    rl.gl.rlUnloadShaderProgram(data.compute_shader);
}

pub fn compute(data: *ParticleData) void {
    _ = data;
    // const dt: f32 = rl.getFrameTime();
    // const speed: f32 = 1.0;

    // const current_set_0 = if (data.current_set == 0) data.ssbo_0_set_0 else data.ssbo_0_set_1;
    // const current_set_1 = if (data.current_set == 0) data.ssbo_1_set_0 else data.ssbo_1_set_1;
    // const next_set_0 = if (data.current_set == 0) data.ssbo_0_set_1 else data.ssbo_0_set_0;
    // const next_set_1 = if (data.current_set == 0) data.ssbo_1_set_1 else data.ssbo_1_set_0;

    // var zero: u32 = 0;
    // rl.gl.rlUpdateShaderBuffer(data.atomic_counter, &zero, @sizeOf(u32), 0);

    // helpers.assertUniformLoc(data.compute_shader, "deltaTime", 0);
    // helpers.assertUniformLoc(data.compute_shader, "speed", 1);

    // rl.gl.rlEnableShader(data.compute_shader);
    // rl.gl.rlSetUniform(0, &dt, @intFromEnum(rl.ShaderUniformDataType.float), 1);
    // rl.gl.rlSetUniform(1, &speed, @intFromEnum(rl.ShaderUniformDataType.float), 1);

    // rl.gl.rlBindShaderBuffer(current_set_0, 0);
    // rl.gl.rlBindShaderBuffer(current_set_1, 1);
    // rl.gl.rlBindShaderBuffer(next_set_0, 2);
    // rl.gl.rlBindShaderBuffer(next_set_1, 3);
    // rl.gl.rlBindShaderBuffer(data.atomic_counter, 4);

    // const groups = (data.alive_count + 1023) / 1024;
    // rl.gl.rlComputeShaderDispatch(@intCast(groups), 1, 1);
    // rl.gl.rlDisableShader();

    // // rl.gl.rlBindShaderBuffer(data.current_ssbo_0, 0);
    // // rl.gl.rlBindShaderBuffer(data.current_ssbo_1, 1);
    // rl.gl.rlComputeShaderDispatch(data.num_particles / 1024, 1, 1);
    // rl.gl.rlDisableShader();
}

pub fn draw(ctx: *Context) void {
    const shader = ctx.shaders.get(.particle).?;
    const particle_scale: f32 = 1.0;

    helpers.assertUniformLoc(shader.id, "particleScale", 0);

    rl.beginShaderMode(shader);
    rl.setShaderValue(shader, 0, &particle_scale, rl.ShaderUniformDataType.float);

    rl.gl.rlBindShaderBuffer(ctx.particle_data.current_ssbo_0, 0);
    rl.gl.rlBindShaderBuffer(ctx.particle_data.current_ssbo_1, 1);

    _ = rl.gl.rlEnableVertexArray(ctx.particle_data.vao);
    rl.gl.rlDrawVertexArrayInstanced(0, 6, @intCast(ctx.particle_data.num_particles));
    rl.gl.rlDisableVertexArray();
    rl.endShaderMode();
}
