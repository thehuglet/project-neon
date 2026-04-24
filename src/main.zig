const Context = @import("context").Context;
const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const TextureAtlas = @import("context").TextureAtlas;
const GpuTextureAtlas = @import("context").GpuTextureAtlas;

const context = @import("context");
const std = @import("std");
const builtin = @import("builtin");
const asset = @import("asset");
const component = @import("component");
const entity = @import("entity");
const enums = @import("enums");
const helpers = @import("helpers");
const rl = @import("raylib");
const system = @import("system");
const debug = @import("debug.zig");
const particle = @import("particle");
const types = @import("types");

pub fn main() !void {
    var threaded_io: std.Io.Threaded = .init_single_threaded;
    const io = threaded_io.io();
    defer threaded_io.deinit();
    const time_now = std.Io.Clock.now(.awake, io).toNanoseconds();
    const allocator = switch (builtin.mode) {
        .Debug, .ReleaseSafe => blk: {
            var gpa = std.heap.DebugAllocator(.{}).init;
            break :blk gpa.allocator();
        },
        .ReleaseFast, .ReleaseSmall => std.heap.c_allocator,
    };
    const rng_seed: u64 = @intCast(time_now);
    var prng = std.Random.DefaultPrng.init(rng_seed);

    // --- Init raylib ---
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
        .msaa_4x_hint = true,
    });
    rl.initWindow(1600, 900, "Project Neon");
    rl.setTargetFPS(144);
    defer rl.closeWindow();

    const glGetTextureHandle = helpers.load_fn_bindless_get_texture_handle();
    const glMakeTextureHandleResident = helpers.load_fn_bindless_make_texture_handle_resident();
    context.setupGlBindlessFnPtrs(glGetTextureHandle, glMakeTextureHandleResident);

    // --- Init context ---
    const atlases: std.EnumMap(enums.AtlasId, TextureAtlas) = .init(.{
        .cube = .init("assets/gen_textures/atlases/cube_atlas.png", 96, 96),
        .roto = .init("assets/gen_textures/atlases/roto_atlas.png", 96, 96),
        .projectile = .init("assets/gen_textures/atlases/projectile_atlas.png", 96, 96),
    });
    var gpu_atlases: std.EnumMap(enums.AtlasId, GpuTextureAtlas) = .init(.{
        .cube = context.buildGpuTextureAtlas(atlases.get(.cube).?),
        .roto = context.buildGpuTextureAtlas(atlases.get(.roto).?),
        .projectile = context.buildGpuTextureAtlas(atlases.get(.projectile).?),
    });
    var ctx = Context{
        .ecs = ECS.init(allocator),
        .allocator = allocator,
        .rng = prng.random(),
        .canvas_size = .{
            .width = 1920,
            .height = 1080,
        },
        .atlases = atlases,
        .gpu_atlases = gpu_atlases,
        .shaders = .init(.{
            .neon_sprite = try rl.loadShader(
                "assets/shaders/neon_sprite.vert",
                "assets/shaders/neon_sprite.frag",
            ),
            .bloom = try rl.loadShader(
                null,
                "assets/shaders/bloom.frag",
            ),
            .starfield = try rl.loadShader(
                null,
                "assets/shaders/starfield.frag",
            ),
            .particle = try rl.loadShader(
                "assets/shaders/particle.vert",
                "assets/shaders/particle.frag",
            ),
        }),
        .game_settings = .{
            .show_hurtboxes = false,
            .show_hitboxes = false,
        },
        .particle_system = particle.init(allocator, &gpu_atlases),
        .player_input_state = .{
            .move_up = false,
            .move_down = false,
            .move_left = false,
            .move_right = false,
            .dash = false,
            .use_primary_fire = false,
            .use_secondary_fire = false,
        },
        .temp = .{
            .hurt_ids = .empty,
            .hurt_positions = .empty,
            .hurt_radii = .empty,
            .hurt_layers = .empty,
        },
    };
    defer ctx.deinit();

    // --- Init canvas ---
    const canvas: rl.RenderTexture2D = try rl.loadRenderTexture(
        ctx.canvas_size.width,
        ctx.canvas_size.height,
    );
    rl.setTextureWrap(canvas.texture, .clamp);
    rl.setTextureFilter(canvas.texture, .bilinear);

    // --- Init starfield shader ---
    {
        const shader = ctx.shaders.get(.starfield).?;
        const resolution = [2]f32{
            @floatFromInt(ctx.canvas_size.width),
            @floatFromInt(ctx.canvas_size.height),
        };
        const resolution_loc = helpers.shaderUniform(shader, "u_resolution");
        rl.setShaderValue(shader, resolution_loc, &resolution, .vec2);
    }

    // --- Init particles projection matrix ---
    {
        const shader = ctx.shaders.get(.particle).?;

        const viewport_width: f32 = @floatFromInt(ctx.canvas_size.width);
        const viewport_height: f32 = @floatFromInt(ctx.canvas_size.height);

        // const aspect_ratio: f32 = viewport_width / viewport_height;
        const ortho = rl.math.matrixOrtho(
            0,
            viewport_width,
            0,
            viewport_height,
            0,
            10,
        );

        const projection_loc: i32 = rl.getShaderLocation(shader, "projection");
        rl.setShaderValueMatrix(shader, projection_loc, ortho);
    }

    // --- Spawn player ---
    _ = entity.player.spawn(&ctx, .init(400.0, 400.0));

    while (!rl.windowShouldClose()) {
        ctx.clearTemp();
        ctx.ecs.beginQuery();

        // --- Pre-draw update ---
        const zero: u32 = 0;
        rl.gl.rlUpdateShaderBuffer(ctx.particle_system.alive_count, &zero, @sizeOf(u32), 0);
        update(&ctx);
        particle.compute(&ctx.particle_system);

        // --- Canvas drawing ---
        rl.beginTextureMode(canvas);
        draw(&ctx);
        particle.draw(&ctx.particle_system, ctx.shaders.get(.particle).?);
        rl.endTextureMode();

        // --- Post-draw update ---
        updatePost(&ctx);
        ctx.ecs.endQuery();

        // ------ Drawing canvas to window ------
        {
            // const bloom_shader = ctx.shaders.get(.bloom).?;
            rl.beginDrawing();
            // rl.beginShaderMode(bloom_shader);

            const canvas_size = rl.Vector2{
                .x = @floatFromInt(ctx.canvas_size.width),
                .y = @floatFromInt(ctx.canvas_size.height),
            };

            const src = rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = canvas_size.x,
                .height = -canvas_size.y,
            };
            const dest_size: rl.Vector2 = helpers.toScreenCoords(canvas_size, canvas_size);
            const dest = rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = dest_size.x,
                .height = dest_size.y,
            };

            rl.drawTexturePro(
                canvas.texture,
                src,
                dest,
                rl.Vector2{ .x = 0, .y = 0 },
                0,
                rl.Color.white,
            );

            // rl.endShaderMode();
            rl.drawFPS(0, 0);
            // Debug particle counter
            {
                const count: u32 = particle.debugGetAliveCount(&ctx.particle_system);
                var buf: [64]u8 = undefined;
                const text = std.fmt.bufPrintZ(&buf, "PARTICLES: {}", .{count}) catch unreachable;

                rl.drawText(text, 200, 0, 20, .white);
            }
            rl.endDrawing();
        }
    }
}

fn update(ctx: *Context) void {
    // --- Temp enemy spawning ---
    if (rl.isKeyPressed(.v)) {
        for (0..5) |_| {
            _ = entity.roto_charger.spawn(&ctx.ecs, ctx.rng, ctx.atlases.get(.roto).?, .{ .x = 100, .y = 200 });
        }
    }

    if (rl.isKeyDown(.f)) {
        particle.spawnBurst(
            &ctx.particle_system,
            .{ .x = 1920.0 * 0.5, .y = 1080.0 * 0.5 },
            .{
                .color = rl.Color.init(230, 100, 80, 255).alpha(0.35),
                .texture = .{ .atlas_id = .projectile, .cell_index = 0 },
                .speed = .{ .range = .{ .min = 50.0, .max = 1000.0 } },
                .scale = .{ .range = .{ .min = 100.0, .max = 100.0 } },
                .scale_over_t = 0.0,
                .alpha_over_t = 0.0,
                .hue_shift_over_t = 2.0,
                .lifetime_sec = .{ .range = .{ .min = 1.0, .max = 1.0 } },
            },
        );
    }

    // --- Systems ---
    system.updateCanvasMousePos(ctx);
    // debug.handleDebugHotkeys(&ctx.game_settings);
    system.playerInputs(ctx);
    system.playerMovement(ctx);
    system.playerDashInit(ctx);
    system.playerWeaponControl(ctx);
    system.setTargetToPlayer(ctx);
    system.handleWeapons(ctx);
    system.updateDash(ctx);
    system.updateDashTrailGhost(ctx);
    system.updateLifetime(ctx);
    // system.chaseEntity(ctx);
    system.spinCosmetic(ctx);
    system.updateDamageFlash(ctx);
    system.updateRingOverTLifetime(ctx);
    system.spinCosmeticAccelScaled(ctx);
    system.playerRotateFacingMouseCosmetic(ctx);
    system.handleCollisions(ctx);
    system.applyMotionToTransform(ctx);
    system.motionApplyDragFriction(ctx);
}

fn draw(ctx: *Context) void {
    system.drawStarfieldBackground(ctx);
    system.drawNeonSprites(ctx);
    system.drawLumenBar(ctx);
    system.drawRingOverT(ctx);
    system.drawPlayerHealth(ctx);
    system.drawNeonSpriteEntityCount(ctx);

    // if (debug_settings.show_hurtboxes) {
    //     system.drawDebugHurtboxes(&ecs);
    // }
    // if (debug_settings.show_hitboxes) {
    //     system.drawDebugHitboxes(&ecs);
    // }
}

fn updatePost(ctx: *Context) void {
    system.oneTickHitbox(ctx);
    // TODO: fix the death related logic, its a mess
    system.despawnOOBEntities(ctx, -200.0);
    system.lifetimeDespawn(&ctx.ecs);
    system.zeroHealthDeath(&ctx.ecs, ctx.rng);
    system.onDeath(ctx);
}
