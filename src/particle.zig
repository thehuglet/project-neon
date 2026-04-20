const Context = @import("context").Context;
const TextureAtlas = @import("context").TextureAtlas;

const std = @import("std");
const rl = @import("raylib");
const helpers = @import("helpers");

const c_glad = @cImport({
    @cInclude("glad.h");
});

const ZERO: u32 = 0;

const ComputeBufLoc = enum(u8) {
    compute_indirect_args = 0,
    draw_indirect_args = 1,
    alive_count = 2,
    prev_alive_count = 3,
    current_particle_state_0 = 4,
    current_particle_state_1 = 5,
    current_particle_state_2 = 6,
    current_particle_state_3 = 7,
    next_particle_state_0 = 8,
    next_particle_state_1 = 9,
    next_particle_state_2 = 10,
    next_particle_state_3 = 11,
};

const ComputeUniLoc = enum(u8) {
    delta_time = 0,
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
    spawn_shader: u32,
    post_compute_shader: u32,

    // Alive counters
    alive_count: u32,
    prev_alive_count: u32,

    // Current and next frame state pair handles
    particle_state_0: [2]u32,
    particle_state_1: [2]u32,
    particle_state_2: [2]u32,
    particle_state_3: [2]u32,
    particle_state_index: u32,

    // Indirect handles
    compute_indirect_args: u32,
    draw_indirect_args: u32,
};

pub fn init(allocator: std.mem.Allocator) ParticleData {
    const compute_shader = blk: {
        const shader_code: [:0]u8 = rl.loadFileText("assets/shaders/particle.comp");
        const shader_id = rl.gl.rlLoadShader(shader_code, rl.gl.rl_compute_shader);
        const program = rl.gl.rlLoadShaderProgramCompute(shader_id);
        rl.unloadFileText(shader_code);
        break :blk program;
    };

    const spawn_shader = blk: {
        const shader_code: [:0]u8 = rl.loadFileText("assets/shaders/particle_spawn.comp");
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

    const max_particles: u32 = 1024 * 50;

    const initial_particle_state_0: []rl.Vector4 = allocator.alloc(rl.Vector4, max_particles) catch @panic("OOM");
    defer allocator.free(initial_particle_state_0);

    const initial_particle_state_1: []rl.Vector4 = allocator.alloc(rl.Vector4, max_particles) catch @panic("OOM");
    defer allocator.free(initial_particle_state_1);

    const initial_particle_state_2: []rl.Vector4 = allocator.alloc(rl.Vector4, max_particles) catch @panic("OOM");
    defer allocator.free(initial_particle_state_2);

    const initial_particle_state_3: []rl.Vector4 = allocator.alloc(rl.Vector4, max_particles) catch @panic("OOM");
    defer allocator.free(initial_particle_state_3);

    for (0..max_particles) |i| {
        // const x_pos: f32 = helpers.randomFloatRange(rng, -1.0, 1.0);
        // const y_pos: f32 = helpers.randomFloatRange(rng, -1.0, 0.8);
        // const lifetime_sec: f32 = helpers.randomFloatRange(rng, 0.3, 0.9);

        initial_particle_state_0[i] = rl.Vector4.init(0.0, 0.0, 0.0, 0.0);
        initial_particle_state_1[i] = rl.Vector4.init(0.0, 0.0, 0.0, 0.0);
        initial_particle_state_2[i] = rl.Vector4.init(0.0, 0.0, 0.0, 0.0);
        initial_particle_state_3[i] = rl.Vector4.init(0.0, 0.0, 0.0, 0.0);
    }

    const particle_state_0 = [_]u32{
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), initial_particle_state_0.ptr, rl.gl.rl_dynamic_copy),
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), initial_particle_state_0.ptr, rl.gl.rl_dynamic_copy),
    };
    const particle_state_1 = [_]u32{
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), initial_particle_state_1.ptr, rl.gl.rl_dynamic_copy),
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), initial_particle_state_1.ptr, rl.gl.rl_dynamic_copy),
    };
    const particle_state_2 = [_]u32{
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), initial_particle_state_2.ptr, rl.gl.rl_dynamic_copy),
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), initial_particle_state_2.ptr, rl.gl.rl_dynamic_copy),
    };

    const particle_state_3 = [_]u32{
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), initial_particle_state_2.ptr, rl.gl.rl_dynamic_copy),
        rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), initial_particle_state_2.ptr, rl.gl.rl_dynamic_copy),
    };

    const alive_count = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &ZERO, rl.gl.rl_dynamic_copy);

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
        .spawn_shader = spawn_shader,
        .post_compute_shader = post_compute_shader,
        .alive_count = alive_count,
        .prev_alive_count = prev_alive_count,
        .particle_state_0 = particle_state_0,
        .particle_state_1 = particle_state_1,
        .particle_state_2 = particle_state_2,
        .particle_state_3 = particle_state_3,
        .particle_state_index = 0,
        .compute_indirect_args = compute_indirect_args,
        .draw_indirect_args = draw_indirect_args,
    };
}

pub fn deinit(data: ParticleData) void {
    rl.gl.rlUnloadVertexArray(data.vao);

    rl.gl.rlUnloadShaderProgram(data.compute_shader);
    rl.gl.rlUnloadShaderProgram(data.spawn_shader);
    rl.gl.rlUnloadShaderProgram(data.post_compute_shader);

    rl.gl.rlUnloadShaderBuffer(data.alive_count);
    rl.gl.rlUnloadShaderBuffer(data.prev_alive_count);

    for (0..2) |i| {
        rl.gl.rlUnloadShaderBuffer(data.particle_state_0[i]);
        rl.gl.rlUnloadShaderBuffer(data.particle_state_1[i]);
        rl.gl.rlUnloadShaderBuffer(data.particle_state_2[i]);
        rl.gl.rlUnloadShaderBuffer(data.particle_state_3[i]);
    }

    rl.gl.rlUnloadShaderBuffer(data.compute_indirect_args);
    rl.gl.rlUnloadShaderBuffer(data.draw_indirect_args);
}

pub fn compute(data: *ParticleData) void {
    const dt: f32 = rl.getFrameTime();

    const current_particle_state_0 = data.particle_state_0[data.particle_state_index];
    const current_particle_state_1 = data.particle_state_1[data.particle_state_index];
    const current_particle_state_2 = data.particle_state_2[data.particle_state_index];
    const current_particle_state_3 = data.particle_state_3[data.particle_state_index];
    const next_particle_state_0 = data.particle_state_0[1 - data.particle_state_index];
    const next_particle_state_1 = data.particle_state_1[1 - data.particle_state_index];
    const next_particle_state_2 = data.particle_state_2[1 - data.particle_state_index];
    const next_particle_state_3 = data.particle_state_3[1 - data.particle_state_index];

    // --- Compute pass ---
    rl.gl.rlEnableShader(data.compute_shader);
    rl.gl.rlSetUniform(
        @intFromEnum(ComputeUniLoc.delta_time),
        &dt,
        @intFromEnum(rl.ShaderUniformDataType.float),
        1,
    );

    rl.gl.rlBindShaderBuffer(current_particle_state_0, @intFromEnum(ComputeBufLoc.current_particle_state_0));
    rl.gl.rlBindShaderBuffer(current_particle_state_1, @intFromEnum(ComputeBufLoc.current_particle_state_1));
    rl.gl.rlBindShaderBuffer(current_particle_state_2, @intFromEnum(ComputeBufLoc.current_particle_state_2));
    rl.gl.rlBindShaderBuffer(current_particle_state_3, @intFromEnum(ComputeBufLoc.current_particle_state_3));
    rl.gl.rlBindShaderBuffer(next_particle_state_0, @intFromEnum(ComputeBufLoc.next_particle_state_0));
    rl.gl.rlBindShaderBuffer(next_particle_state_1, @intFromEnum(ComputeBufLoc.next_particle_state_1));
    rl.gl.rlBindShaderBuffer(next_particle_state_2, @intFromEnum(ComputeBufLoc.next_particle_state_2));
    rl.gl.rlBindShaderBuffer(next_particle_state_3, @intFromEnum(ComputeBufLoc.next_particle_state_3));
    rl.gl.rlBindShaderBuffer(data.alive_count, @intFromEnum(ComputeBufLoc.alive_count));
    rl.gl.rlBindShaderBuffer(data.prev_alive_count, @intFromEnum(ComputeBufLoc.prev_alive_count));
    rl.gl.rlBindShaderBuffer(data.draw_indirect_args, @intFromEnum(ComputeBufLoc.draw_indirect_args));

    c_glad.glBindBuffer(c_glad.GL_DISPATCH_INDIRECT_BUFFER, data.compute_indirect_args);
    c_glad.glDispatchComputeIndirect(0);
    c_glad.glMemoryBarrier(c_glad.GL_SHADER_STORAGE_BARRIER_BIT);
    rl.gl.rlDisableShader();

    // --- Post compute pass ---
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

pub fn draw(data: *ParticleData, particle_shader: rl.Shader, viewport_width: i32, viewport_height: i32) void {
    const particle_scale: f32 = 10.0;

    const particle_state_0 = data.particle_state_0[data.particle_state_index];
    const particle_state_1 = data.particle_state_1[data.particle_state_index];
    const particle_state_2 = data.particle_state_2[data.particle_state_index];
    const particle_state_3 = data.particle_state_3[data.particle_state_index];

    rl.beginShaderMode(particle_shader);

    rl.setShaderValue(
        particle_shader,
        @intFromEnum(DrawUniLoc.particle_scale),
        &particle_scale,
        rl.ShaderUniformDataType.float,
    );
    const cell_w: i32 = 96;
    const cell_h: i32 = 96;
    const tex_w: i32 = 1024;
    const tex_h: i32 = 1048;
    const viewport_w: f32 = @floatFromInt(viewport_width);
    const viewport_h: f32 = @floatFromInt(viewport_height);
    rl.setShaderValue(particle_shader, 2, &cell_w, rl.ShaderUniformDataType.int);
    rl.setShaderValue(particle_shader, 3, &cell_h, rl.ShaderUniformDataType.int);
    rl.setShaderValue(particle_shader, 4, &tex_w, rl.ShaderUniformDataType.int);
    rl.setShaderValue(particle_shader, 5, &tex_h, rl.ShaderUniformDataType.int);
    rl.setShaderValue(particle_shader, 6, &[_]f32{ viewport_w, viewport_h }, rl.ShaderUniformDataType.vec2);

    rl.gl.rlBindShaderBuffer(particle_state_0, @intFromEnum(ComputeBufLoc.current_particle_state_0));
    rl.gl.rlBindShaderBuffer(particle_state_1, @intFromEnum(ComputeBufLoc.current_particle_state_1));
    rl.gl.rlBindShaderBuffer(particle_state_2, @intFromEnum(ComputeBufLoc.current_particle_state_2));
    rl.gl.rlBindShaderBuffer(particle_state_3, @intFromEnum(ComputeBufLoc.current_particle_state_3));

    _ = rl.gl.rlEnableVertexArray(data.vao);

    c_glad.glBindBuffer(c_glad.GL_DRAW_INDIRECT_BUFFER, data.draw_indirect_args);
    c_glad.glDrawArraysIndirect(c_glad.GL_TRIANGLES, null);

    rl.gl.rlDisableVertexArray();
    rl.endShaderMode();
}

pub fn spawnBurst(
    data: *ParticleData,
    count: u32,
    center: rl.Vector2,
    radius: f32,
    atlas: *const TextureAtlas,
) void {
    if (count == 0) return;

    const groups = (count + 1023) / 1024;
    const seed: f32 = @floatCast(rl.getTime());

    rl.gl.rlEnableShader(data.spawn_shader);

    // Uniforms
    rl.gl.rlSetUniform(0, &data.max_particles, @intFromEnum(rl.ShaderUniformDataType.int), 1);
    rl.gl.rlSetUniform(1, &count, @intFromEnum(rl.ShaderUniformDataType.int), 1);
    rl.gl.rlSetUniform(2, &seed, @intFromEnum(rl.ShaderUniformDataType.float), 1);
    rl.gl.rlSetUniform(3, &center, @intFromEnum(rl.ShaderUniformDataType.vec2), 1);
    rl.gl.rlSetUniform(4, &radius, @intFromEnum(rl.ShaderUniformDataType.float), 1);
    const handle = atlas.bindless_handle;
    const handle_lo: u32 = @truncate(handle);
    const handle_hi: u32 = @truncate(handle >> 32);
    // rl.SetUniform shat itself here, needed glad
    c_glad.glUniform2ui(5, handle_lo, handle_hi);
    const cell_count: i32 = atlas.cols * atlas.rows;
    rl.gl.rlSetUniform(6, &cell_count, @intFromEnum(rl.ShaderUniformDataType.int), 1);
    rl.gl.rlSetUniform(7, &atlas.cols, @intFromEnum(rl.ShaderUniformDataType.int), 1);
    rl.gl.rlSetUniform(8, &atlas.rows, @intFromEnum(rl.ShaderUniformDataType.int), 1);

    // Bind the NEXT state buffers (where we'll write new particles)
    const next_0 = data.particle_state_0[1 - data.particle_state_index];
    const next_1 = data.particle_state_1[1 - data.particle_state_index];
    const next_2 = data.particle_state_2[1 - data.particle_state_index];
    const next_3 = data.particle_state_3[1 - data.particle_state_index];
    rl.gl.rlBindShaderBuffer(next_0, @intFromEnum(ComputeBufLoc.next_particle_state_0));
    rl.gl.rlBindShaderBuffer(next_1, @intFromEnum(ComputeBufLoc.next_particle_state_1));
    rl.gl.rlBindShaderBuffer(next_2, @intFromEnum(ComputeBufLoc.next_particle_state_2));
    rl.gl.rlBindShaderBuffer(next_3, @intFromEnum(ComputeBufLoc.next_particle_state_3));
    rl.gl.rlBindShaderBuffer(data.alive_count, @intFromEnum(ComputeBufLoc.alive_count));

    rl.gl.rlComputeShaderDispatch(groups, 1, 1);

    c_glad.glMemoryBarrier(c_glad.GL_SHADER_STORAGE_BARRIER_BIT);
    rl.gl.rlDisableShader();
}

/// Blocking operation, don't use in production.
pub fn debugGetAliveCount(data: *ParticleData) u32 {
    var count: u32 = 0;
    rl.gl.rlReadShaderBuffer(data.alive_count, &count, @sizeOf(u32), 0);
    return count;
}
