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
    vao: u32,
    max_particles: u32,
    atomic_counter: u32,
    // alive_count: u32,
    prev_alive_buffer: u32,
    // alive_counters: [2]u32,
    // alive_fences: [2]c_glad.GLsync,
    // current_alive_index: u8,
    compute_shader: u32,
    post_compute_shader: u32,
    ssbo_0_set_0: u32,
    ssbo_1_set_0: u32,
    ssbo_0_set_1: u32,
    ssbo_1_set_1: u32,
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

    const max_particles: u32 = 1024 * 1000 * 8;

    const ssbo_0_data: []rl.Vector4 = allocator.alloc(rl.Vector4, max_particles) catch @panic("OOM");
    defer allocator.free(ssbo_0_data);

    const ssbo_1_data: []rl.Vector4 = allocator.alloc(rl.Vector4, max_particles) catch @panic("OOM");
    defer allocator.free(ssbo_1_data);

    for (0..max_particles) |i| {
        const x_pos: f32 = helpers.randomFloatRange(rng, -1.0, 1.0);
        const y_pos: f32 = helpers.randomFloatRange(rng, -1.0, 0.8);
        const lifetime_sec: f32 = helpers.randomFloatRange(rng, 6.0, 8.0);
        // const lifetime_sec: f32 = 0.0;

        ssbo_0_data[i] = rl.Vector4.init(x_pos, y_pos, lifetime_sec, 0.0);
        ssbo_1_data[i] = rl.Vector4.init(0.0, 0.0, 0.0, 0.0);
    }

    const ssbo_0_set_0 = rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), ssbo_0_data.ptr, rl.gl.rl_dynamic_copy);
    const ssbo_1_set_0 = rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), ssbo_1_data.ptr, rl.gl.rl_dynamic_copy);
    const ssbo_0_set_1 = rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), ssbo_0_data.ptr, rl.gl.rl_dynamic_copy);
    const ssbo_1_set_1 = rl.gl.rlLoadShaderBuffer(max_particles * @sizeOf(rl.Vector4), ssbo_1_data.ptr, rl.gl.rl_dynamic_copy);

    const atomic_counter = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &zero, rl.gl.rl_dynamic_copy);

    const initial_groups = (max_particles + 1023) / 1024;
    const indirect_data = [_]u32{ initial_groups, 1, 1 };
    const indirect_buffer = rl.gl.rlLoadShaderBuffer(3 * @sizeOf(u32), &indirect_data, rl.gl.rl_dynamic_copy);

    const prev_alive_data = max_particles;
    const prev_alive_buffer = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &prev_alive_data, rl.gl.rl_dynamic_copy);

    // const alive_counter_0 = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &zero, rl.gl.rl_dynamic_copy);
    // const alive_counter_1 = rl.gl.rlLoadShaderBuffer(@sizeOf(u32), &zero, rl.gl.rl_dynamic_copy);

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
        // .alive_count = max_particles,
        .prev_alive_buffer = prev_alive_buffer,
        // .alive_counters = [2]u32{ alive_counter_0, alive_counter_1 },
        // .alive_fences = [2]c_glad.GLsync{ null, null },
        .compute_shader = compute_shader,
        .post_compute_shader = post_compute_shader,
        .ssbo_0_set_0 = ssbo_0_set_0,
        .ssbo_1_set_0 = ssbo_1_set_0,
        .ssbo_0_set_1 = ssbo_0_set_1,
        .ssbo_1_set_1 = ssbo_1_set_1,
        .indirect_buffer = indirect_buffer,
        .current_set = 0,
        // .current_alive_index = 0,
        .draw_indirect_buffer = draw_indirect_buffer,
    };
}

pub fn deinit(data: ParticleData) void {
    rl.gl.rlUnloadShaderBuffer(data.ssbo_0_set_0);
    rl.gl.rlUnloadShaderBuffer(data.ssbo_1_set_0);
    rl.gl.rlUnloadShaderBuffer(data.ssbo_0_set_1);
    rl.gl.rlUnloadShaderBuffer(data.ssbo_1_set_1);
    // rl.gl.rlUnloadShaderBuffer(data.alive_counters[0]);
    // rl.gl.rlUnloadShaderBuffer(data.alive_counters[1]);
    rl.gl.rlUnloadShaderBuffer(data.prev_alive_buffer);
    rl.gl.rlUnloadShaderBuffer(data.indirect_buffer);
    rl.gl.rlUnloadVertexArray(data.vao);
    rl.gl.rlUnloadShaderProgram(data.compute_shader);
    rl.gl.rlUnloadShaderProgram(data.post_compute_shader);
    // for (data.alive_fences) |fence| {
    //     if (fence) |f| c_glad.glDeleteSync(f);
    // }
}

pub fn compute(data: *ParticleData) void {
    const zero: u32 = 0;
    // if (data.alive_count == 0) return;

    // const zero: u32 = 0;
    const dt: f32 = rl.getFrameTime();
    const speed: f32 = 1.0;

    const current_set_0 = if (data.current_set == 0) data.ssbo_0_set_0 else data.ssbo_0_set_1;
    const current_set_1 = if (data.current_set == 0) data.ssbo_1_set_0 else data.ssbo_1_set_1;
    const next_set_0 = if (data.current_set == 0) data.ssbo_0_set_1 else data.ssbo_0_set_0;
    const next_set_1 = if (data.current_set == 0) data.ssbo_1_set_1 else data.ssbo_1_set_0;

    rl.gl.rlUpdateShaderBuffer(data.atomic_counter, &zero, @sizeOf(u32), 0);

    // --- compute pass ---
    // TODO: store shader locs in particle data next time and use these instead,
    // possible driver fuckery going on in the background???????
    // helpers.assertUniformLoc(data.compute_shader, "deltaTime", 0);
    // helpers.assertUniformLoc(data.compute_shader, "speed", 1);

    rl.gl.rlEnableShader(data.compute_shader);
    rl.gl.rlSetUniform(0, &dt, @intFromEnum(rl.ShaderUniformDataType.float), 1);
    rl.gl.rlSetUniform(1, &speed, @intFromEnum(rl.ShaderUniformDataType.float), 1);

    rl.gl.rlBindShaderBuffer(current_set_0, 0);
    rl.gl.rlBindShaderBuffer(current_set_1, 1);
    rl.gl.rlBindShaderBuffer(next_set_0, 2);
    rl.gl.rlBindShaderBuffer(next_set_1, 3);
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

    // var debug_cmd: struct { count: u32, instanceCount: u32, first: u32, baseInstance: u32 } = undefined;
    // c_glad.glBindBuffer(c_glad.GL_SHADER_STORAGE_BUFFER, data.draw_indirect_buffer);
    // c_glad.glGetBufferSubData(c_glad.GL_SHADER_STORAGE_BUFFER, 0, @sizeOf(@TypeOf(debug_cmd)), &debug_cmd);
    // c_glad.glBindBuffer(c_glad.GL_SHADER_STORAGE_BUFFER, 0);
    // std.debug.print("Draw indirect: count={}, instanceCount={}\n", .{ debug_cmd.count, debug_cmd.instanceCount });

    // if (data.alive_fences[write_idx]) |old_fence| {
    //     c_glad.glDeleteSync(old_fence);
    // }
    // const fence = c_glad.glFenceSync(c_glad.GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
    // data.alive_fences[write_idx] = fence;

    // data.current_alive_index = 1 - write_idx;

    // var debug_lifetimes: [10]f32 = undefined;
    // c_glad.glBindBuffer(c_glad.GL_SHADER_STORAGE_BUFFER, next_set_0);
    // c_glad.glGetBufferSubData(c_glad.GL_SHADER_STORAGE_BUFFER, 0, @sizeOf(f32) * 10, &debug_lifetimes);
    // c_glad.glBindBuffer(c_glad.GL_SHADER_STORAGE_BUFFER, 0);
    // std.debug.print("First 10 lifetimes:", .{});
    // for (debug_lifetimes) |life| {
    //     std.debug.print(" {d:.2}", .{life});
    // }
    // std.debug.print("\n", .{});

    // var new_alive: u32 = 0;
    // rl.gl.rlReadShaderBuffer(data.atomic_counter, &new_alive, @sizeOf(u32), 0);
    // data.alive_count = new_alive;

    // var debug_lifetimes: [10]f32 = undefined;
    // c_glad.glBindBuffer(c_glad.GL_SHADER_STORAGE_BUFFER, next_set_0);
    // c_glad.glGetBufferSubData(c_glad.GL_SHADER_STORAGE_BUFFER, 0, @sizeOf(f32) * 10, &debug_lifetimes);
    // c_glad.glBindBuffer(c_glad.GL_SHADER_STORAGE_BUFFER, 0);
    // std.debug.print("First 10 lifetimes:", .{});
    // for (debug_lifetimes) |life| {
    //     std.debug.print(" {d:.2}", .{life});
    // }
    // std.debug.print("\n", .{});

    data.current_set = 1 - data.current_set;
    // std.debug.print("{}\n", .{data.alive_count});
    // std.debug.print("{}\n", .{data.compute_shader});
}

pub fn draw(ctx: *Context) void {
    const shader = ctx.shaders.get(.particle).?;
    const particle_scale: f32 = 1.0;

    // Bind SSBOs for the current particle data set (unchanged)
    const cur0 = if (ctx.particle_data.current_set == 0)
        ctx.particle_data.ssbo_0_set_0
    else
        ctx.particle_data.ssbo_0_set_1;
    const cur1 = if (ctx.particle_data.current_set == 0)
        ctx.particle_data.ssbo_1_set_0
    else
        ctx.particle_data.ssbo_1_set_1;

    rl.beginShaderMode(shader);
    const scale_loc = rl.getShaderLocation(shader, "particleScale");
    rl.setShaderValue(shader, scale_loc, &particle_scale, rl.ShaderUniformDataType.float);

    rl.gl.rlBindShaderBuffer(cur0, 0);
    rl.gl.rlBindShaderBuffer(cur1, 1);

    _ = rl.gl.rlEnableVertexArray(ctx.particle_data.vao);

    // Indirect draw – the instance count comes from the GPU buffer
    c_glad.glBindBuffer(c_glad.GL_DRAW_INDIRECT_BUFFER, ctx.particle_data.draw_indirect_buffer);
    c_glad.glDrawArraysIndirect(c_glad.GL_TRIANGLES, @ptrFromInt(0));

    rl.gl.rlDisableVertexArray();
    rl.endShaderMode();
}

// pub fn draw(ctx: *Context) void {
//     if (ctx.particle_data.alive_count == 0) return;
//     // updateAliveCount(&ctx.particle_data);

//     const shader = ctx.shaders.get(.particle).?;
//     const particle_scale: f32 = 1.0;

//     const cur0 = if (ctx.particle_data.current_set == 0)
//         ctx.particle_data.ssbo_0_set_0
//     else
//         ctx.particle_data.ssbo_0_set_1;
//     const cur1 = if (ctx.particle_data.current_set == 0)
//         ctx.particle_data.ssbo_1_set_0
//     else
//         ctx.particle_data.ssbo_1_set_1;

//     rl.beginShaderMode(shader);
//     const scale_loc = rl.getShaderLocation(shader, "particleScale");
//     rl.setShaderValue(shader, scale_loc, &particle_scale, rl.ShaderUniformDataType.float);

//     rl.gl.rlBindShaderBuffer(cur0, 0);
//     rl.gl.rlBindShaderBuffer(cur1, 1);

//     _ = rl.gl.rlEnableVertexArray(ctx.particle_data.vao);
//     rl.gl.rlDrawVertexArrayInstanced(0, 6, @intCast(ctx.particle_data.alive_count));
//     rl.gl.rlDisableVertexArray();
//     rl.endShaderMode();
// }

// /// Reads the counter from two frames ago.
// fn updateAliveCount(data: *ParticleData) void {
//     const read_idx = 1 - data.current_alive_index;
//     const fence = data.alive_fences[read_idx];
//     if (fence) |f| {
//         // Wait up to 1 ms for the fence to signal
//         const result = c_glad.glClientWaitSync(f, 0, 1_000_000);
//         if (result == c_glad.GL_ALREADY_SIGNALED or result == c_glad.GL_CONDITION_SATISFIED) {
//             var count: u32 = 0;
//             rl.gl.rlReadShaderBuffer(data.alive_counters[read_idx], &count, @sizeOf(u32), 0);
//             data.alive_count = count;
//             c_glad.glDeleteSync(f);
//             data.alive_fences[read_idx] = null;
//         }
//         // else: not ready yet – keep old alive_count
//     }
// }
