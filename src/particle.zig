const Context = @import("context").Context;

const std = @import("std");
const rl = @import("raylib");
const helpers = @import("helpers");
const c_glad = @cImport({
    @cInclude("glad.h");
});

const DrawCmdIndirect = struct {
    count: c_uint,
    instanceCount: c_uint,
    first: c_uint,
    baseInstance: c_uint,
};

pub const ParticleData = struct {
    max_particles: u32,

    vao: u32,
    atomic_counter: u32,
    prev_alive_buffer: u32,
    compute_shader: u32,
    post_compute_shader: u32,
    packed_ssbo_0: [2]u32,
    packed_ssbo_1: [2]u32,
    indirect_buffer: u32,
    current_set: u8,
    draw_indirect_buffer: u32,
};

pub fn init(allocator: std.mem.Allocator, rng: std.Random) ParticleData {
    const zero: u32 = 0;

    const compute_shader: u32 = blk: {
        const shader_code: [:0]u8 = rl.loadFileText("assets/shaders/particle_compute.glsl");
        const shader_id = rl.gl.rlLoadShader(shader_code, rl.gl.rl_compute_shader);
        const program = rl.gl.rlLoadShaderProgramCompute(shader_id);
        rl.unloadFileText(shader_code);
        break :blk program;
    };

    const post_compute_shader: u32 = blk: {
        const shader_code: [:0]u8 = rl.loadFileText("assets/shaders/particle_post_compute.glsl");
        std.debug.print("Post-compute shader length: {}\n", .{shader_code.len});
        const shader_id = rl.gl.rlLoadShader(shader_code, rl.gl.rl_compute_shader);
        const program = rl.gl.rlLoadShaderProgramCompute(shader_id);
        rl.unloadFileText(shader_code);

        break :blk program;
    };

    const max_particles: u32 = 1024 * 1000;

    const ssbo_0_data: []rl.Vector4 = allocator.alloc(rl.Vector4, max_particles) catch @panic("OOM");
    defer allocator.free(ssbo_0_data);

    const ssbo_1_data: []rl.Vector4 = allocator.alloc(rl.Vector4, max_particles) catch @panic("OOM");
    defer allocator.free(ssbo_1_data);

    for (0..max_particles) |i| {
        const x_pos: f32 = helpers.randomFloatRange(rng, -1.0, 1.0);
        const y_pos: f32 = helpers.randomFloatRange(rng, -1.0, 0.8);
        const lifetime_sec: f32 = helpers.randomFloatRange(rng, 0.3, 5.0);

        ssbo_0_data[i] = rl.Vector4.init(x_pos, y_pos, lifetime_sec, 0.0);
        ssbo_1_data[i] = rl.Vector4.init(0.0, 0.0, 0.0, 0.0);
    }

    const packed_ssbo_0 = [_]u32{
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), ssbo_0_data.ptr, rl.gl.rl_dynamic_copy),
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), ssbo_0_data.ptr, rl.gl.rl_dynamic_copy),
    };
    const packed_ssbo_1 = [_]u32{
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), ssbo_1_data.ptr, rl.gl.rl_dynamic_copy),
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), ssbo_1_data.ptr, rl.gl.rl_dynamic_copy),
    };

    const atomic_counter = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &zero, rl.gl.rl_dynamic_copy);

    const initial_groups = (max_particles + 1023) / 1024;
    const indirect_data = [_]u32{ initial_groups, 1, 1 };
    const indirect_buffer = rl.gl.rlLoadShaderBuffer(3 * @sizeOf(u32), &indirect_data, rl.gl.rl_dynamic_copy);

    const prev_alive_data = max_particles;
    const prev_alive_buffer = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &prev_alive_data, rl.gl.rl_dynamic_copy);

    const draw_cmd_data = DrawCmdIndirect{
        .count = 6,
        .instanceCount = max_particles,
        .first = 0,
        .baseInstance = 0,
    };
    const draw_indirect_buffer = rl.gl.rlLoadShaderBuffer(@sizeOf(@TypeOf(draw_cmd_data)), &draw_cmd_data, rl.gl.rl_dynamic_draw);

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
        .atomic_counter = atomic_counter,
        .prev_alive_buffer = prev_alive_buffer,
        .compute_shader = compute_shader,
        .post_compute_shader = post_compute_shader,
        .packed_ssbo_0 = packed_ssbo_0,
        .packed_ssbo_1 = packed_ssbo_1,
        .indirect_buffer = indirect_buffer,
        .current_set = 0,
        .draw_indirect_buffer = draw_indirect_buffer,
    };
}

pub fn deinit(data: ParticleData) void {
    rl.gl.rlUnloadShaderBuffer(data.ssbo_0_set_0);
    rl.gl.rlUnloadShaderBuffer(data.ssbo_1_set_0);
    rl.gl.rlUnloadShaderBuffer(data.ssbo_0_set_1);
    rl.gl.rlUnloadShaderBuffer(data.ssbo_1_set_1);
    rl.gl.rlUnloadShaderBuffer(data.prev_alive_buffer);
    rl.gl.rlUnloadShaderBuffer(data.indirect_buffer);
    rl.gl.rlUnloadVertexArray(data.vao);
    rl.gl.rlUnloadShaderProgram(data.compute_shader);
    rl.gl.rlUnloadShaderProgram(data.post_compute_shader);
}

pub fn compute(data: *ParticleData) void {
    const zero: u32 = 0;
    const dt: f32 = rl.getFrameTime();
    const speed: f32 = 1.0;

    const current_packed_ssbo_0 = data.packed_ssbo_0[data.current_set];
    const current_packed_ssbo_1 = data.packed_ssbo_1[data.current_set];
    const next_packed_ssbo_0 = data.packed_ssbo_0[1 - data.current_set];
    const next_packed_ssbo_1 = data.packed_ssbo_1[1 - data.current_set];

    rl.gl.rlUpdateShaderBuffer(data.atomic_counter, &zero, @sizeOf(u32), 0);

    rl.gl.rlEnableShader(data.compute_shader);
    rl.gl.rlSetUniform(0, &dt, @intFromEnum(rl.ShaderUniformDataType.float), 1);
    rl.gl.rlSetUniform(1, &speed, @intFromEnum(rl.ShaderUniformDataType.float), 1);

    rl.gl.rlBindShaderBuffer(current_packed_ssbo_0, 0);
    rl.gl.rlBindShaderBuffer(current_packed_ssbo_1, 1);
    rl.gl.rlBindShaderBuffer(next_packed_ssbo_0, 2);
    rl.gl.rlBindShaderBuffer(next_packed_ssbo_1, 3);
    rl.gl.rlBindShaderBuffer(data.atomic_counter, 4);
    rl.gl.rlBindShaderBuffer(data.prev_alive_buffer, 6);
    rl.gl.rlBindShaderBuffer(data.draw_indirect_buffer, 7);

    c_glad.glBindBuffer(c_glad.GL_DISPATCH_INDIRECT_BUFFER, data.indirect_buffer);
    c_glad.glDispatchComputeIndirect(0);
    c_glad.glMemoryBarrier(c_glad.GL_SHADER_STORAGE_BARRIER_BIT);
    rl.gl.rlDisableShader();

    // --- post compute pass ---
    rl.gl.rlEnableShader(data.post_compute_shader);
    rl.gl.rlBindShaderBuffer(data.atomic_counter, 4);
    rl.gl.rlBindShaderBuffer(data.indirect_buffer, 5);
    rl.gl.rlBindShaderBuffer(data.prev_alive_buffer, 6);
    rl.gl.rlBindShaderBuffer(data.draw_indirect_buffer, 7);
    rl.gl.rlComputeShaderDispatch(1, 1, 1);
    rl.gl.rlDisableShader();

    c_glad.glMemoryBarrier(c_glad.GL_COMMAND_BARRIER_BIT | c_glad.GL_SHADER_STORAGE_BARRIER_BIT);

    data.current_set = 1 - data.current_set;
}

pub fn draw(data: *ParticleData, particle_shader: rl.Shader) void {
    const particle_scale: f32 = 1.0;

    const current_packed_ssbo_0 = data.packed_ssbo_0[data.current_set];
    const current_packed_ssbo_1 = data.packed_ssbo_1[data.current_set];

    rl.beginShaderMode(particle_shader);

    const scale_loc = rl.getShaderLocation(particle_shader, "particleScale");
    rl.setShaderValue(particle_shader, scale_loc, &particle_scale, rl.ShaderUniformDataType.float);

    rl.gl.rlBindShaderBuffer(current_packed_ssbo_0, 0);
    rl.gl.rlBindShaderBuffer(current_packed_ssbo_1, 1);

    _ = rl.gl.rlEnableVertexArray(data.vao);

    c_glad.glBindBuffer(c_glad.GL_DRAW_INDIRECT_BUFFER, data.draw_indirect_buffer);
    c_glad.glDrawArraysIndirect(c_glad.GL_TRIANGLES, @ptrFromInt(0));

    rl.gl.rlDisableVertexArray();
    rl.endShaderMode();
}
