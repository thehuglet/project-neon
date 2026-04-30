const Context = @import("context").Context;
const TextureAtlas = @import("context").TextureAtlas;
const GpuTextureAtlas = @import("context").GpuTextureAtlas;

const std = @import("std");
const rl = @import("raylib");
const helpers = @import("helpers");
const types = @import("types");
const enums = @import("enums");

const c_glad = @cImport({
    @cInclude("glad.h");
});

const MAX_PARTICLE_COUNT: u32 = 1024 * 250;

const U_TYPE_INT: u32 = @intFromEnum(rl.ShaderUniformDataType.int);
const U_TYPE_FLOAT: u32 = @intFromEnum(rl.ShaderUniformDataType.float);
const U_TYPE_VEC2: u32 = @intFromEnum(rl.ShaderUniformDataType.vec2);
const U_TYPE_VEC4: u32 = @intFromEnum(rl.ShaderUniformDataType.vec4);
const ZERO: u32 = 0;

const DRAW_BLUR_PASS: i32 = 0;
const DRAW_CLEAN_PASS: i32 = 1;

const MAX_GPU_TEXTURE_ATLASES = 64;

pub const Spec = struct {
    color: rl.Color = .pink,
    clean_colorize_factor: f32 = 1.0,
    speed: types.F32FlatOrRange = .{ .range = .{
        .min = 10.0,
        .max = 800.0,
    } },
    scale: types.F32FlatOrRange = .{ .flat = 100.0 },
    /// Extra velocity applied on top of the speed used in rand radial
    extra_velocity: rl.Vector2 = .{ .x = 0.0, .y = 0.0 },
    scale_over_t: f32 = 1.0,
    alpha_over_t: f32 = 1.0,
    hue_shift_over_t: f32 = 0.0,
    spin_speed: f32 = 0.0,
    lifetime_sec: types.F32FlatOrRange = .{ .flat = 1.0 },
    texture: struct {
        atlas_id: enums.AtlasId,
        cell_index: usize,
    },
};

pub const Emitter = struct {
    count: u32 = 100,
};

const DrawIndirectData = struct {
    count: c_uint,
    instanceCount: c_uint,
    first: c_uint,
    baseInstance: c_uint,
};

/// Mirrors GPU layout.
const ParticleState = extern struct {
    // --- 16 ---
    position_x: f32 = 0.0,
    position_y: f32 = 0.0,
    velocity_x: f32 = 0.0,
    velocity_y: f32 = 0.0,
    // --- 16 ---
    color_r: f32 = 0.0,
    color_g: f32 = 0.0,
    color_b: f32 = 0.0,
    color_a: f32 = 0.0,
    // --- 16 ---
    atlas_id: u32 = 0,
    atlas_cell_index: u32 = 0,
    initial_lifetime_sec: f32 = 0.0,
    lifetime_sec: f32 = 0.0,
    // --- 16 ---
    rotation: f32 = 0.0,
    spin_speed: f32 = 0.0,
    scale: f32 = 0.0,
    scale_over_t: f32 = 0.0,
    // --- 16 ---
    alpha_over_t: f32 = 0.0,
    hue_shift_over_t: f32 = 0.0,
    clean_colorize_factor: f32 = 0.0,
    _pad2: u32 = 0,
};

pub const ParticleSystem = struct {
    max_particle_count: u32,
    vao: u32,
    update_shader: u32,
    indirect_cmd_shader: u32,
    spawn_shader: u32,
    // --- Uniform locations ---
    update_shader_uniforms: struct {
        delta_time: i32,
    },
    spawn_shader_uniforms: struct {
        seed: i32,
        max_particles: i32,
        count: i32,
        atlas_id: i32,
        atlas_cell_index: i32,
        position: i32,
        spawn_radius: i32,
        color: i32,
        speed: i32,
        extra_velocity: i32,
        scale: i32,
        spin_speed: i32,
        scale_over_t: i32,
        alpha_over_t: i32,
        hue_shift_over_t: i32,
        lifetime_sec: i32,
        clean_colorize_factor: i32,
    },
    draw_shader_uniforms: struct {
        projection: i32,
        viewport_height: i32,
        render_pass: i32,
    },
    // --- Buffer bindings ---
    update_shader_bindings: struct {
        alive_count: u32,
        prev_alive_count: u32,
        current_state: u32,
        next_state: u32,
    },
    spawn_shader_bindings: struct {
        alive_count: u32,
        next_particle_state: u32,
    },
    indirect_cmd_shader_bindings: struct {
        compute_indirect_args: u32,
        draw_indirect_args: u32,
        alive_count: u32,
        prev_alive_count: u32,
    },
    draw_shader_bindings: struct {
        current_state: u32,
        atlases: u32,
    },
    // --- Buffer handles ---
    atlases: u32,
    alive_count: u32,
    prev_alive_count: u32,
    particle_state: [2]u32,
    particle_state_index: u32,
    indirect_dispatch_args: u32,
    indirect_draw_args: u32,
};

pub fn init(
    allocator: std.mem.Allocator,
    gpu_atlases: *std.EnumMap(enums.AtlasId, GpuTextureAtlas),
    draw_shader: rl.Shader,
    viewport_height: u32,
) ParticleSystem {
    const update_shader = loadComputeShaderProgram("assets/shaders/particle_update.comp");
    const spawn_shader = loadComputeShaderProgram("assets/shaders/particle_spawn.comp");
    const indirect_cmd_shader = loadComputeShaderProgram("assets/shaders/particle_indirect_cmd.comp");

    const initial_particle_state: []ParticleState = allocator.alloc(ParticleState, MAX_PARTICLE_COUNT) catch
        @panic("OOM");
    defer allocator.free(initial_particle_state);

    for (initial_particle_state) |*p| {
        p.* = .{};
    }
    const particle_state = [_]u32{
        rl.gl.rlLoadShaderBuffer(
            MAX_PARTICLE_COUNT * @sizeOf(ParticleState),
            initial_particle_state.ptr,
            rl.gl.rl_dynamic_copy,
        ),
        rl.gl.rlLoadShaderBuffer(
            MAX_PARTICLE_COUNT * @sizeOf(ParticleState),
            initial_particle_state.ptr,
            rl.gl.rl_dynamic_copy,
        ),
    };
    var atlas_array: [MAX_GPU_TEXTURE_ATLASES]GpuTextureAtlas = undefined;
    {
        var iter = gpu_atlases.iterator();
        while (iter.next()) |entry| {
            atlas_array[@intFromEnum(entry.key)] = entry.value.*;
        }
    }

    const atlas_array_size = atlas_array.len * @sizeOf(GpuTextureAtlas);
    const buf_atlases = rl.gl.rlLoadShaderBuffer(atlas_array_size, &atlas_array, rl.gl.rl_dynamic_copy);
    const buf_alive_count = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &ZERO, rl.gl.rl_dynamic_copy);
    const buf_prev_alive_count = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &MAX_PARTICLE_COUNT, rl.gl.rl_dynamic_copy);

    // --- Init indirect dispatch args ---
    const initial_groups = (MAX_PARTICLE_COUNT + 1023) / 1024;
    const indirect_dispatch_data = [_]u32{ initial_groups, 1, 1 };
    const indirect_dispatch_args = rl.gl.rlLoadShaderBuffer(
        3 * @sizeOf(u32),
        &indirect_dispatch_data,
        rl.gl.rl_dynamic_copy,
    );

    // --- Init indirect draw args ---
    const draw_indirect_data = DrawIndirectData{
        .count = 6,
        .instanceCount = MAX_PARTICLE_COUNT,
        .first = 0,
        .baseInstance = 0,
    };
    const indirect_draw_args = rl.gl.rlLoadShaderBuffer(
        @sizeOf(@TypeOf(draw_indirect_data)),
        &draw_indirect_data,
        rl.gl.rl_dynamic_draw,
    );

    // --- Init vertex data ---
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

    const uni = rl.gl.rlGetLocationUniform;

    // --- Init persistent uniforms ---
    const viewport_height_u_loc = uni(draw_shader.id, "viewportHeight");
    const viewport_height_f32: f32 = @floatFromInt(viewport_height);
    rl.setShaderValue(
        draw_shader,
        viewport_height_u_loc,
        &viewport_height_f32,
        .float,
    );

    return ParticleSystem{
        .max_particle_count = MAX_PARTICLE_COUNT,
        .vao = vao,
        .update_shader = update_shader,
        .spawn_shader = spawn_shader,
        .indirect_cmd_shader = indirect_cmd_shader,
        .update_shader_uniforms = .{
            .delta_time = uni(update_shader, "deltaTime"),
        },
        .spawn_shader_uniforms = .{
            .max_particles = uni(spawn_shader, "maxParticles"),
            .count = uni(spawn_shader, "count"),
            .seed = uni(spawn_shader, "seed"),
            .position = uni(spawn_shader, "position"),
            .spawn_radius = uni(spawn_shader, "spawnRadius"),
            .atlas_id = uni(spawn_shader, "atlasId"),
            .atlas_cell_index = uni(spawn_shader, "atlasCellIndex"),
            .color = uni(spawn_shader, "color"),
            .speed = uni(spawn_shader, "speed"),
            .extra_velocity = uni(spawn_shader, "extraVelocity"),
            .scale = uni(spawn_shader, "scale"),
            .spin_speed = uni(spawn_shader, "spinSpeed"),
            .scale_over_t = uni(spawn_shader, "scaleOverT"),
            .alpha_over_t = uni(spawn_shader, "alphaOverT"),
            .hue_shift_over_t = uni(spawn_shader, "hueShiftOverT"),
            .lifetime_sec = uni(spawn_shader, "lifetimeSec"),
            .clean_colorize_factor = uni(spawn_shader, "cleanColorizeFactor"),
        },
        .draw_shader_uniforms = .{
            .projection = uni(draw_shader.id, "projection"),
            .viewport_height = viewport_height_u_loc,
            .render_pass = uni(draw_shader.id, "renderPass"),
        },
        .update_shader_bindings = .{
            .alive_count = 0,
            .prev_alive_count = 1,
            .current_state = 2,
            .next_state = 3,
        },
        .spawn_shader_bindings = .{
            .alive_count = 0,
            .next_particle_state = 1,
        },
        .indirect_cmd_shader_bindings = .{
            .compute_indirect_args = 0,
            .draw_indirect_args = 1,
            .alive_count = 2,
            .prev_alive_count = 3,
        },
        .draw_shader_bindings = .{
            .current_state = 0,
            .atlases = 1,
        },
        .atlases = buf_atlases,
        .alive_count = buf_alive_count,
        .prev_alive_count = buf_prev_alive_count,
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

pub fn startFrameCleanup(system: *ParticleSystem) void {
    rl.gl.rlUpdateShaderBuffer(system.alive_count, &ZERO, @sizeOf(u32), 0);
}

pub fn compute(system: *ParticleSystem) void {
    // --- Update pass ---
    rl.gl.rlEnableShader(system.update_shader);
    {
        // --- Uniforms ---
        {
            const dt: f32 = rl.getFrameTime();
            const u = &system.update_shader_uniforms;

            rl.gl.rlSetUniform(u.delta_time, &dt, U_TYPE_FLOAT, 1);
        }

        // --- Buffers ---
        {
            const current_particle_state: u32 = system.particle_state[system.particle_state_index];
            const next_particle_state: u32 = system.particle_state[1 - system.particle_state_index];
            const b = &system.update_shader_bindings;

            rl.gl.rlBindShaderBuffer(system.alive_count, b.alive_count);
            rl.gl.rlBindShaderBuffer(system.prev_alive_count, b.prev_alive_count);
            rl.gl.rlBindShaderBuffer(current_particle_state, b.current_state);
            rl.gl.rlBindShaderBuffer(next_particle_state, b.next_state);
        }
    }
    c_glad.glBindBuffer(c_glad.GL_DISPATCH_INDIRECT_BUFFER, system.indirect_dispatch_args);
    c_glad.glDispatchComputeIndirect(0);
    c_glad.glMemoryBarrier(c_glad.GL_SHADER_STORAGE_BARRIER_BIT);
    rl.gl.rlDisableShader();

    // --- Dispatch args pass ---
    rl.gl.rlEnableShader(system.indirect_cmd_shader);
    {
        const b = &system.indirect_cmd_shader_bindings;

        rl.gl.rlBindShaderBuffer(system.indirect_dispatch_args, b.compute_indirect_args);
        rl.gl.rlBindShaderBuffer(system.indirect_draw_args, b.draw_indirect_args);
        rl.gl.rlBindShaderBuffer(system.alive_count, b.alive_count);
        rl.gl.rlBindShaderBuffer(system.prev_alive_count, b.prev_alive_count);
    }
    rl.gl.rlComputeShaderDispatch(1, 1, 1);
    rl.gl.rlDisableShader();

    c_glad.glMemoryBarrier(c_glad.GL_COMMAND_BARRIER_BIT | c_glad.GL_SHADER_STORAGE_BARRIER_BIT);

    system.particle_state_index = 1 - system.particle_state_index;
}

pub fn draw(system: *ParticleSystem, particle_shader: rl.Shader) void {
    const current_particle_state = system.particle_state[system.particle_state_index];

    rl.beginBlendMode(.additive);
    rl.beginShaderMode(particle_shader);

    _ = rl.gl.rlEnableVertexArray(system.vao);
    c_glad.glBindBuffer(c_glad.GL_DRAW_INDIRECT_BUFFER, system.indirect_draw_args);

    // --- Buffers ---
    {
        const b = &system.draw_shader_bindings;

        rl.gl.rlBindShaderBuffer(current_particle_state, b.current_state);
        rl.gl.rlBindShaderBuffer(system.atlases, b.atlases);
    }

    // --- Blur pass ---
    {
        const u = &system.draw_shader_uniforms;
        rl.setShaderValue(particle_shader, u.render_pass, &DRAW_BLUR_PASS, .int);
        c_glad.glDrawArraysIndirect(c_glad.GL_TRIANGLES, null);
    }

    // --- Clean pass ---
    {
        const u = &system.draw_shader_uniforms;
        rl.setShaderValue(particle_shader, u.render_pass, &DRAW_CLEAN_PASS, .int);
        c_glad.glDrawArraysIndirect(c_glad.GL_TRIANGLES, null);
    }

    rl.gl.rlDisableVertexArray();
    rl.endShaderMode();
    rl.endBlendMode();
}

pub fn spawnBurst(system: *ParticleSystem, pos: rl.Vector2, spec: Spec, emitter: Emitter) void {
    // TODO: implement these properly:
    const spawn_radius: f32 = 0.0;

    rl.gl.rlEnableShader(system.spawn_shader);

    // --- Uniforms ---
    {
        const seed: f32 = @floatCast(rl.getTime());
        const scale: rl.Vector2 = spec.scale.toF32Range().toVec2();
        const speed: rl.Vector2 = spec.speed.toF32Range().toVec2();
        const lifetime_sec: rl.Vector2 = spec.lifetime_sec.toF32Range().toVec2();
        const atlas_id: i32 = @intFromEnum(spec.texture.atlas_id);
        const atlas_cell_index: i32 = @intCast(spec.texture.cell_index);
        const color_normalized: rl.Vector4 = spec.color.normalize();
        const u = &system.spawn_shader_uniforms;

        rl.gl.rlSetUniform(u.max_particles, &system.max_particle_count, U_TYPE_INT, 1);
        rl.gl.rlSetUniform(u.count, &emitter.count, U_TYPE_INT, 1);
        rl.gl.rlSetUniform(u.seed, &seed, U_TYPE_FLOAT, 1);
        rl.gl.rlSetUniform(u.position, &pos, U_TYPE_VEC2, 1);
        rl.gl.rlSetUniform(u.spawn_radius, &spawn_radius, U_TYPE_FLOAT, 1);
        rl.gl.rlSetUniform(u.atlas_id, &atlas_id, U_TYPE_INT, 1);
        rl.gl.rlSetUniform(u.atlas_cell_index, &atlas_cell_index, U_TYPE_INT, 1);
        rl.gl.rlSetUniform(u.color, &color_normalized, U_TYPE_VEC4, 1);
        rl.gl.rlSetUniform(u.scale, &scale, U_TYPE_VEC2, 1);
        rl.gl.rlSetUniform(u.scale_over_t, &spec.scale_over_t, U_TYPE_FLOAT, 1);
        rl.gl.rlSetUniform(u.alpha_over_t, &spec.alpha_over_t, U_TYPE_FLOAT, 1);
        rl.gl.rlSetUniform(u.hue_shift_over_t, &spec.hue_shift_over_t, U_TYPE_FLOAT, 1);
        rl.gl.rlSetUniform(u.speed, &speed, U_TYPE_VEC2, 1);
        rl.gl.rlSetUniform(u.spin_speed, &spec.spin_speed, U_TYPE_FLOAT, 1);
        rl.gl.rlSetUniform(u.extra_velocity, &spec.extra_velocity, U_TYPE_VEC2, 1);
        rl.gl.rlSetUniform(u.lifetime_sec, &lifetime_sec, U_TYPE_VEC2, 1);
        rl.gl.rlSetUniform(u.clean_colorize_factor, &spec.clean_colorize_factor, U_TYPE_FLOAT, 1);
    }

    // --- Buffers ---
    {
        const next_particle_state: u32 = system.particle_state[1 - system.particle_state_index];
        const b = &system.spawn_shader_bindings;

        rl.gl.rlBindShaderBuffer(system.alive_count, b.alive_count);
        rl.gl.rlBindShaderBuffer(next_particle_state, b.next_particle_state);
    }

    // --- Dispatch ---
    const groups: u32 = (emitter.count + 1023) / 1024;
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
