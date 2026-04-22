const Context = @import("context").Context;
const TextureAtlas = @import("context").TextureAtlas;

const std = @import("std");
const rl = @import("raylib");
const helpers = @import("helpers");
const types = @import("types");

const c_glad = @cImport({
    @cInclude("glad.h");
});

const U_TYPE_INT: u32 = @intFromEnum(rl.ShaderUniformDataType.int);
const U_TYPE_FLOAT: u32 = @intFromEnum(rl.ShaderUniformDataType.float);
const U_TYPE_VEC2: u32 = @intFromEnum(rl.ShaderUniformDataType.vec2);
const ZERO: u32 = 0;

pub const Spec = struct {
    color: rl.Color,
    speed: union(enum) {
        flat: f32,
        range: types.Range,
    },
    scale: union(enum) {
        flat: f32,
        range: types.Range,
    },
    lifetime_sec: union(enum) {
        flat: f32,
        range: types.Range,
    },
    texture: struct {
        atlas: TextureAtlas,
        cell_index: u32,
    },
    // gravity_scale: types.Range,
};

const ComputeBufLoc = enum(u8) {
    compute_indirect_args = 0,
    draw_indirect_args = 1,
    alive_count = 2,
    prev_alive_count = 3,
    current_particle_state = 4,
    next_particle_state = 5,
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

/// Mirrored from GLSL side. Misalignment = UB.
const ParticleState = extern struct {
    // --- 16 bytes ---
    position: @Vector(2, f32) align(8),
    velocity: @Vector(2, f32) align(8),

    // --- 16 bytes ---
    color: @Vector(4, f32) align(16),

    // --- 16 bytes ---
    atlasHandle: @Vector(2, u32) align(8),
    atlasCols: u32,
    atlasRows: u32,

    // --- 16 bytes ---
    atlasCellIndex: u32,
    lifetimeSec: f32,
    rotation: f32,
    scale: f32,
};

pub const ParticleSystem = struct {
    max_particles: u32,
    vao: u32,
    update_shader: u32,
    indirect_cmd_shader: u32,
    spawn_shader: u32,
    // --- Uniform locations ---
    update_shader_uniforms: struct {
        delta_time: i32,
    },
    spawn_shader_uniforms: struct {
        max_particles: i32,
        count: i32,
        global_seed: i32,
        position: i32,
        spawn_radius: i32,
        atlas_handle: i32,
        atlas_cell_cols: i32,
        atlas_cell_rows: i32,
        color: i32,
        scale_range: i32,
        speed_range: i32,
    },
    // draw_uniforms: struct {
    //     projection: i32,
    //     cell_width_px: i32,
    //     cell_height_px: i32,

    // },
    // --- Buffer handles ---
    alive_count: u32,
    prev_alive_count: u32,
    particle_state: [2]u32,
    particle_state_index: u32,
    indirect_dispatch_args: u32,
    indirect_draw_args: u32,
};

pub fn init(allocator: std.mem.Allocator) ParticleSystem {
    const update_shader = loadComputeShaderProgram("assets/shaders/particle_update.comp");
    const spawn_shader = loadComputeShaderProgram("assets/shaders/particle_spawn.comp");
    const indirect_cmd_shader = loadComputeShaderProgram("assets/shaders/particle_indirect_cmd.comp");

    const max_particles: u32 = 1024 * 250;

    const initial_particle_state: []ParticleState = allocator.alloc(ParticleState, max_particles) catch @panic("OOM");
    defer allocator.free(initial_particle_state);

    for (initial_particle_state) |*p| {
        p.* = .{
            .position = .{ 0.0, 0.0 },
            .velocity = .{ 0.0, 0.0 },
            .color = .{ 0.0, 0.0, 0.0, 0.0 },
            .atlasHandle = .{ 0, 0 },
            .atlasCols = 0,
            .atlasRows = 0,
            .atlasCellIndex = 0,
            .lifetimeSec = 0.0,
            .rotation = 0.0,
            .scale = 0.0,
        };
    }
    const particle_state = [_]u32{
        rl.gl.rlLoadShaderBuffer(
            max_particles * @sizeOf(ParticleState),
            initial_particle_state.ptr,
            rl.gl.rl_dynamic_copy,
        ),
        rl.gl.rlLoadShaderBuffer(
            max_particles * @sizeOf(ParticleState),
            initial_particle_state.ptr,
            rl.gl.rl_dynamic_copy,
        ),
    };

    // --- Init indirect dispatch args ---
    const initial_groups = (max_particles + 1023) / 1024;
    const indirect_dispatch_data = [_]u32{ initial_groups, 1, 1 };
    const indirect_dispatch_args = rl.gl.rlLoadShaderBuffer(
        3 * @sizeOf(u32),
        &indirect_dispatch_data,
        rl.gl.rl_dynamic_copy,
    );

    // --- Init indirect draw args ---
    const draw_indirect_data = DrawIndirectData{
        .count = 6,
        .instanceCount = max_particles,
        .first = 0,
        .baseInstance = 0,
    };
    const indirect_draw_args = rl.gl.rlLoadShaderBuffer(
        @sizeOf(@TypeOf(draw_indirect_data)),
        &draw_indirect_data,
        rl.gl.rl_dynamic_draw,
    );

    // --- Init vertex ---
    const vao = rl.gl.rlLoadVertexArray();
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

    return ParticleSystem{
        .max_particles = max_particles,
        .vao = vao,
        .update_shader = update_shader,
        .spawn_shader = spawn_shader,
        .indirect_cmd_shader = indirect_cmd_shader,
        .update_shader_uniforms = .{
            .delta_time = rl.gl.rlGetLocationUniform(update_shader, "deltaTime"),
        },
        .spawn_shader_uniforms = .{
            .max_particles = rl.gl.rlGetLocationUniform(spawn_shader, "maxParticles"),
            .count = rl.gl.rlGetLocationUniform(spawn_shader, "count"),
            .global_seed = rl.gl.rlGetLocationUniform(spawn_shader, "globalSeed"),
            .position = rl.gl.rlGetLocationUniform(spawn_shader, "position"),
            .spawn_radius = rl.gl.rlGetLocationUniform(spawn_shader, "spawnRadius"),
            .atlas_handle = rl.gl.rlGetLocationUniform(spawn_shader, "atlasHandle"),
            .atlas_cell_cols = rl.gl.rlGetLocationUniform(spawn_shader, "atlasCellCols"),
            .atlas_cell_rows = rl.gl.rlGetLocationUniform(spawn_shader, "atlasCellRows"),
            .color = rl.gl.rlGetLocationUniform(spawn_shader, "color"),
            .scale_range = rl.gl.rlGetLocationUniform(spawn_shader, "scaleRange"),
            .speed_range = rl.gl.rlGetLocationUniform(spawn_shader, "speedRange"),
        },
        .alive_count = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &ZERO, rl.gl.rl_dynamic_copy),
        .prev_alive_count = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &max_particles, rl.gl.rl_dynamic_copy),
        .particle_state = particle_state,
        .particle_state_index = 0,
        .indirect_dispatch_args = indirect_dispatch_args,
        .indirect_draw_args = indirect_draw_args,
    };
}

pub fn deinit(system: *ParticleSystem) void {
    rl.gl.rlUnloadVertexArray(system.vao);
    rl.gl.rlUnloadShaderProgram(system.update_shader);
    rl.gl.rlUnloadShaderProgram(system.spawn_shader);
    rl.gl.rlUnloadShaderProgram(system.indirect_cmd_shader);
    rl.gl.rlUnloadShaderBuffer(system.alive_count);
    rl.gl.rlUnloadShaderBuffer(system.prev_alive_count);
    rl.gl.rlUnloadShaderBuffer(system.particle_state[0]);
    rl.gl.rlUnloadShaderBuffer(system.particle_state[1]);
    rl.gl.rlUnloadShaderBuffer(system.indirect_dispatch_args);
    rl.gl.rlUnloadShaderBuffer(system.indirect_draw_args);
}

pub fn compute(system: *ParticleSystem) void {
    const dt: f32 = rl.getFrameTime();
    const current_particle_state = system.particle_state[system.particle_state_index];
    const next_particle_state = system.particle_state[1 - system.particle_state_index];

    // --- Update pass ---
    rl.gl.rlEnableShader(system.update_shader);
    rl.gl.rlSetUniform(system.update_shader_uniforms.delta_time, &dt, U_TYPE_FLOAT, 1);

    rl.gl.rlBindShaderBuffer(current_particle_state, @intFromEnum(ComputeBufLoc.current_particle_state));
    rl.gl.rlBindShaderBuffer(next_particle_state, @intFromEnum(ComputeBufLoc.next_particle_state));
    rl.gl.rlBindShaderBuffer(system.alive_count, @intFromEnum(ComputeBufLoc.alive_count));
    rl.gl.rlBindShaderBuffer(system.prev_alive_count, @intFromEnum(ComputeBufLoc.prev_alive_count));
    rl.gl.rlBindShaderBuffer(system.indirect_draw_args, @intFromEnum(ComputeBufLoc.draw_indirect_args));

    c_glad.glBindBuffer(c_glad.GL_DISPATCH_INDIRECT_BUFFER, system.indirect_dispatch_args);
    c_glad.glDispatchComputeIndirect(0);
    c_glad.glMemoryBarrier(c_glad.GL_SHADER_STORAGE_BARRIER_BIT);
    rl.gl.rlDisableShader();

    // --- Post compute pass ---
    rl.gl.rlEnableShader(system.indirect_cmd_shader);
    rl.gl.rlBindShaderBuffer(system.alive_count, @intFromEnum(ComputeBufLoc.alive_count));
    rl.gl.rlBindShaderBuffer(system.prev_alive_count, @intFromEnum(ComputeBufLoc.prev_alive_count));
    rl.gl.rlBindShaderBuffer(system.indirect_dispatch_args, @intFromEnum(ComputeBufLoc.compute_indirect_args));
    rl.gl.rlBindShaderBuffer(system.indirect_draw_args, @intFromEnum(ComputeBufLoc.draw_indirect_args));
    rl.gl.rlComputeShaderDispatch(1, 1, 1);
    rl.gl.rlDisableShader();

    c_glad.glMemoryBarrier(c_glad.GL_COMMAND_BARRIER_BIT | c_glad.GL_SHADER_STORAGE_BARRIER_BIT);

    system.particle_state_index = 1 - system.particle_state_index;
}

pub fn draw(system: *ParticleSystem, particle_shader: rl.Shader, viewport_width: i32, viewport_height: i32) void {
    const current_particle_state = system.particle_state[system.particle_state_index];

    rl.beginShaderMode(particle_shader);
    rl.beginBlendMode(.additive);

    // const cell_w: i32 = 96;
    // const cell_h: i32 = 96;
    // const tex_w: i32 = 1024;
    // const tex_h: i32 = 1024;
    // const viewport_w: f32 = @floatFromInt(viewport_width);
    // const viewport_h: f32 = @floatFromInt(viewport_height);
    // rl.setShaderValue(particle_shader, 2, &cell_w, rl.ShaderUniformDataType.int);
    // rl.setShaderValue(particle_shader, 3, &cell_h, rl.ShaderUniformDataType.int);
    // rl.setShaderValue(particle_shader, 4, &tex_w, rl.ShaderUniformDataType.int);
    // rl.setShaderValue(particle_shader, 5, &tex_h, rl.ShaderUniformDataType.int);
    // rl.setShaderValue(particle_shader, 6, &[_]f32{ viewport_w, viewport_h }, rl.ShaderUniformDataType.vec2);

    // const render_pass: u32 = 1;
    // const atlas_cell_size_uv = rl.Vector2.init(
    //      / @as(f32, @floatFromInt(viewport_width)),
    // );

    rl.setShaderValue(particle_shader, 7, &render_pass, rl.ShaderUniformDataType.int);
    rl.setShaderValue(particle_shader, 8, &atlas_cell_size_uv, rl.ShaderUniformDataType.vec2);

    rl.gl.rlBindShaderBuffer(current_particle_state, @intFromEnum(ComputeBufLoc.current_particle_state));
    _ = rl.gl.rlEnableVertexArray(system.vao);
    c_glad.glBindBuffer(c_glad.GL_DRAW_INDIRECT_BUFFER, system.indirect_draw_args);

    // --- Blur pass ---
    const pass0: u32 = 0;
    rl.setShaderValue(particle_shader, 7, &pass0, rl.ShaderUniformDataType.int);
    c_glad.glDrawArraysIndirect(c_glad.GL_TRIANGLES, null);

    // // --- Clean pass ---
    const pass1: u32 = 1;
    rl.setShaderValue(particle_shader, 7, &pass1, rl.ShaderUniformDataType.int);
    c_glad.glDrawArraysIndirect(c_glad.GL_TRIANGLES, null);

    rl.gl.rlDisableVertexArray();
    rl.endBlendMode();
    rl.endShaderMode();
}

pub fn spawnBurst(
    system: *ParticleSystem,
    pos: rl.Vector2,
    spec: Spec,
) void {
    // TODO: implement these properly:
    const count: u32 = 7;
    const spawn_radius: f32 = 0.0;

    const groups: u32 = (count + 1023) / 1024;
    const seed: f32 = @floatCast(rl.getTime());

    rl.gl.rlEnableShader(system.spawn_shader);

    const scale_range: rl.Vector2 = switch (spec.scale) {
        .flat => |s| rl.Vector2{ .x = s, .y = s },
        .range => |r| rl.Vector2{ .x = r.min, .y = r.max },
    };
    const speed_range: rl.Vector2 = switch (spec.scale) {
        .flat => |s| rl.Vector2{ .x = s, .y = s },
        .range => |r| rl.Vector2{ .x = r.min, .y = r.max },
    };

    const u = &system.spawn_shader_uniforms;
    rl.gl.rlSetUniform(u.max_particles, &system.max_particles, U_TYPE_INT, 1);
    rl.gl.rlSetUniform(u.count, &count, U_TYPE_INT, 1);
    rl.gl.rlSetUniform(u.global_seed, &seed, U_TYPE_FLOAT, 1);
    rl.gl.rlSetUniform(u.position, &pos, U_TYPE_VEC2, 1);
    rl.gl.rlSetUniform(u.spawn_radius, &spawn_radius, U_TYPE_FLOAT, 1);

    const handle = spec.texture.atlas.bindless_handle;
    const handle_lo: u32 = @truncate(handle);
    const handle_hi: u32 = @truncate(handle >> 32);
    c_glad.glUniform2ui(5, handle_lo, handle_hi);
    rl.gl.rlSetUniform(7, &spec.texture.atlas.cols, @intFromEnum(rl.ShaderUniformDataType.int), 1);
    rl.gl.rlSetUniform(8, &spec.texture.atlas.rows, @intFromEnum(rl.ShaderUniformDataType.int), 1);
    const color_normalized: rl.Vector4 = spec.color.normalize();
    rl.gl.rlSetUniform(9, &color_normalized, @intFromEnum(rl.ShaderUniformDataType.vec4), 1);
    rl.gl.rlSetUniform(10, &scale_range, @intFromEnum(rl.ShaderUniformDataType.vec2), 1);
    rl.gl.rlSetUniform(11, &speed_range, @intFromEnum(rl.ShaderUniformDataType.vec2), 1);

    const next_particle_state = system.particle_state[1 - system.particle_state_index];

    rl.gl.rlBindShaderBuffer(next_particle_state, @intFromEnum(ComputeBufLoc.next_particle_state));
    rl.gl.rlBindShaderBuffer(system.alive_count, @intFromEnum(ComputeBufLoc.alive_count));

    rl.gl.rlComputeShaderDispatch(groups, 1, 1);

    c_glad.glMemoryBarrier(c_glad.GL_SHADER_STORAGE_BARRIER_BIT);
    rl.gl.rlDisableShader();
}

/// Blocking operation, don't use in production.
pub fn debugGetAliveCount(data: *ParticleSystem) u32 {
    var count: u32 = 0;
    rl.gl.rlReadShaderBuffer(data.alive_count, &count, @sizeOf(u32), 0);
    return count;
}

fn loadComputeShaderProgram(path: [:0]const u8) u32 {
    const shader_code: [:0]u8 = rl.loadFileText(path);
    const shader_id = rl.gl.rlLoadShader(shader_code, rl.gl.rl_compute_shader);
    rl.unloadFileText(shader_code);
    const program = rl.gl.rlLoadShaderProgramCompute(shader_id);
    return program;
}
