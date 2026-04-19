const Context = @import("context").Context;

const std = @import("std");
const rl = @import("raylib");
const helpers = @import("helpers");
const c_glad = @cImport({
    @cInclude("glad.h");
});

const ComputeBufLoc = enum(u8) {
    current_particle_state_0 = 0,
    current_particle_state_1 = 1,
    next_particle_state_0 = 2,
    next_particle_state_1 = 3,
    alive_count = 4,
    prev_alive_count = 5,
    compute_indirect_args = 6,
    draw_indirect_args = 7,
};

const ComputeUniLoc = enum(u8) {
    delta_time = 0,
};

const DrawBufLoc = enum(u8) {
    particle_state_0 = 0,
    particle_state_1 = 1,
};

const DrawUniLoc = enum(u8) {
    particle_scale = 0,
};

const DrawIndirectData = struct {
    count: c_uint,
    instanceCount: c_uint,
    first: c_uint,
    baseInstance: c_uint,
};

pub const ParticleData = struct {
    max_particles: u32,

    // Compute shaders & VAO handles
    vao: u32,
    compute_shader: u32,
    post_compute_shader: u32,

    // Alive counters
    alive_count: u32,
    prev_alive_count: u32,

    // Current and next frame state pair handles
    particle_state_0: [2]u32,
    particle_state_1: [2]u32,
    particle_state_index: u32,

    // Indirect handles
    compute_indirect_args: u32,
    draw_indirect_args: u32,
};

pub fn init(allocator: std.mem.Allocator, rng: std.Random) ParticleData {
    const zero: u32 = 0;

    const compute_shader = blk: {
        const shader_code: [:0]u8 = rl.loadFileText("assets/shaders/particle.comp");
        const shader_id = rl.gl.rlLoadShader(shader_code, rl.gl.rl_compute_shader);
        const program = rl.gl.rlLoadShaderProgramCompute(shader_id);
        rl.unloadFileText(shader_code);
        break :blk program;
    };

    const post_compute_shader = blk: {
        const shader_code: [:0]u8 = rl.loadFileText("assets/shaders/particle_post.comp");
        const shader_id = rl.gl.rlLoadShader(shader_code, rl.gl.rl_compute_shader);
        const program = rl.gl.rlLoadShaderProgramCompute(shader_id);
        rl.unloadFileText(shader_code);
        break :blk program;
    };

    const max_particles: u32 = 1024 * 1000;

    const initial_particle_state_0: []rl.Vector4 = allocator.alloc(rl.Vector4, max_particles) catch
        @panic("OOM");
    defer allocator.free(initial_particle_state_0);
    const initial_particle_state_1: []rl.Vector4 = allocator.alloc(rl.Vector4, max_particles) catch
        @panic("OOM");
    defer allocator.free(initial_particle_state_1);

    for (0..max_particles) |i| {
        const x_pos: f32 = helpers.randomFloatRange(rng, -1.0, 1.0);
        const y_pos: f32 = helpers.randomFloatRange(rng, -1.0, 0.8);
        const lifetime_sec: f32 = helpers.randomFloatRange(rng, 0.3, 5.0);

        initial_particle_state_0[i] = rl.Vector4.init(x_pos, y_pos, lifetime_sec, 0.0);
        initial_particle_state_1[i] = rl.Vector4.init(0.0, 0.0, 0.0, 0.0);
    }

    const particle_state_0 = [_]u32{
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), initial_particle_state_0.ptr, rl.gl.rl_dynamic_copy),
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), initial_particle_state_0.ptr, rl.gl.rl_dynamic_copy),
    };
    const particle_state_1 = [_]u32{
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), initial_particle_state_1.ptr, rl.gl.rl_dynamic_copy),
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), initial_particle_state_1.ptr, rl.gl.rl_dynamic_copy),
    };

    const alive_count = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &zero, rl.gl.rl_dynamic_copy);

    const initial_groups = (max_particles + 1023) / 1024;
    const compute_indirect_data = [_]u32{ initial_groups, 1, 1 };
    const compute_indirect_args = rl.gl.rlLoadShaderBuffer(3 * @sizeOf(u32), &compute_indirect_data, rl.gl.rl_dynamic_copy);

    const prev_alive_data = max_particles;
    const prev_alive_count = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &prev_alive_data, rl.gl.rl_dynamic_copy);

    const draw_indirect_data = DrawIndirectData{
        .count = 6,
        .instanceCount = max_particles,
        .first = 0,
        .baseInstance = 0,
    };
    const draw_indirect_args = rl.gl.rlLoadShaderBuffer(@sizeOf(@TypeOf(draw_indirect_data)), &draw_indirect_data, rl.gl.rl_dynamic_draw);

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
        .max_particles = max_particles,
        .vao = vao,
        .compute_shader = compute_shader,
        .post_compute_shader = post_compute_shader,
        .alive_count = alive_count,
        .prev_alive_count = prev_alive_count,
        .particle_state_0 = particle_state_0,
        .particle_state_1 = particle_state_1,
        .particle_state_index = 0,
        .compute_indirect_args = compute_indirect_args,
        .draw_indirect_args = draw_indirect_args,
    };
}

pub fn deinit(data: ParticleData) void {
    rl.gl.rlUnloadVertexArray(data.vao);

    rl.gl.rlUnloadShaderProgram(data.compute_shader);
    rl.gl.rlUnloadShaderProgram(data.post_compute_shader);

    rl.gl.rlUnloadShaderBuffer(data.alive_count);
    rl.gl.rlUnloadShaderBuffer(data.prev_alive_count);

    rl.gl.rlUnloadShaderBuffer(data.particle_state_0[0]);
    rl.gl.rlUnloadShaderBuffer(data.particle_state_0[1]);
    rl.gl.rlUnloadShaderBuffer(data.particle_state_1[0]);
    rl.gl.rlUnloadShaderBuffer(data.particle_state_1[1]);

    rl.gl.rlUnloadShaderBuffer(data.compute_indirect_args);
    rl.gl.rlUnloadShaderBuffer(data.draw_indirect_args);
}

pub fn compute(data: *ParticleData) void {
    const zero: u32 = 0;
    const dt: f32 = rl.getFrameTime();

    const current_particle_state_0 = data.particle_state_0[data.particle_state_index];
    const current_particle_state_1 = data.particle_state_1[data.particle_state_index];
    const next_particle_state_0 = data.particle_state_0[1 - data.particle_state_index];
    const next_particle_state_1 = data.particle_state_1[1 - data.particle_state_index];

    rl.gl.rlUpdateShaderBuffer(data.alive_count, &zero, @sizeOf(u32), 0);

    // --- compute pass ---
    rl.gl.rlEnableShader(data.compute_shader);
    rl.gl.rlSetUniform(
        @intFromEnum(ComputeUniLoc.delta_time),
        &dt,
        @intFromEnum(rl.ShaderUniformDataType.float),
        1,
    );

    rl.gl.rlBindShaderBuffer(current_particle_state_0, @intFromEnum(ComputeBufLoc.current_particle_state_0));
    rl.gl.rlBindShaderBuffer(current_particle_state_1, @intFromEnum(ComputeBufLoc.current_particle_state_1));
    rl.gl.rlBindShaderBuffer(next_particle_state_0, @intFromEnum(ComputeBufLoc.next_particle_state_0));
    rl.gl.rlBindShaderBuffer(next_particle_state_1, @intFromEnum(ComputeBufLoc.next_particle_state_1));
    rl.gl.rlBindShaderBuffer(data.alive_count, @intFromEnum(ComputeBufLoc.alive_count));
    rl.gl.rlBindShaderBuffer(data.prev_alive_count, @intFromEnum(ComputeBufLoc.prev_alive_count));
    rl.gl.rlBindShaderBuffer(data.draw_indirect_args, @intFromEnum(ComputeBufLoc.draw_indirect_args));

    c_glad.glBindBuffer(c_glad.GL_DISPATCH_INDIRECT_BUFFER, data.compute_indirect_args);
    c_glad.glDispatchComputeIndirect(0);
    c_glad.glMemoryBarrier(c_glad.GL_SHADER_STORAGE_BARRIER_BIT);
    rl.gl.rlDisableShader();

    // --- post compute pass ---
    rl.gl.rlEnableShader(data.post_compute_shader);
    rl.gl.rlBindShaderBuffer(data.alive_count, @intFromEnum(ComputeBufLoc.alive_count));
    rl.gl.rlBindShaderBuffer(data.prev_alive_count, @intFromEnum(ComputeBufLoc.prev_alive_count));
    rl.gl.rlBindShaderBuffer(data.compute_indirect_args, @intFromEnum(ComputeBufLoc.compute_indirect_args));
    rl.gl.rlBindShaderBuffer(data.draw_indirect_args, @intFromEnum(ComputeBufLoc.draw_indirect_args));
    rl.gl.rlComputeShaderDispatch(1, 1, 1);
    rl.gl.rlDisableShader();

    c_glad.glMemoryBarrier(c_glad.GL_COMMAND_BARRIER_BIT | c_glad.GL_SHADER_STORAGE_BARRIER_BIT);

    data.particle_state_index = 1 - data.particle_state_index;
}

pub fn draw(data: *ParticleData, particle_shader: rl.Shader) void {
    const particle_scale: f32 = 1.0;

    const particle_state_0 = data.particle_state_0[data.particle_state_index];
    const particle_state_1 = data.particle_state_1[data.particle_state_index];

    rl.beginShaderMode(particle_shader);

    rl.setShaderValue(
        particle_shader,
        @intFromEnum(DrawUniLoc.particle_scale),
        &particle_scale,
        rl.ShaderUniformDataType.float,
    );

    rl.gl.rlBindShaderBuffer(particle_state_0, @intFromEnum(DrawBufLoc.particle_state_0));
    rl.gl.rlBindShaderBuffer(particle_state_1, @intFromEnum(DrawBufLoc.particle_state_1));

    _ = rl.gl.rlEnableVertexArray(data.vao);

    c_glad.glBindBuffer(c_glad.GL_DRAW_INDIRECT_BUFFER, data.draw_indirect_args);
    c_glad.glDrawArraysIndirect(c_glad.GL_TRIANGLES, null);

    rl.gl.rlDisableVertexArray();
    rl.endShaderMode();
}
