const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");
const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const Context = @import("context").Context;
const TextureAtlas = @import("context").TextureAtlas;
const entity = @import("entity");
const component = @import("component");
const system = @import("system");
const asset = @import("asset");
const helpers = @import("helpers");
const debug = @import("debug.zig");
const enums = @import("enums");

const WINDOW_WIDTH = 1920;
const WINDOW_HEIGHT = 1080;

const CANVAS_WIDTH = 1920;
const CANVAS_HEIGHT = 1090;
const CANVAS_WIDTH_F32: f32 = @floatFromInt(CANVAS_WIDTH);
const CANVAS_HEIGHT_F32: f32 = @floatFromInt(CANVAS_HEIGHT);

pub fn main() !void {
    const allocator = switch (builtin.mode) {
        .Debug, .ReleaseSafe => blk: {
            // For development, use DebugAllocator for its safety checks
            var gpa = std.heap.DebugAllocator(.{}).init;
            // Don't forget to defer gpa.deinit()!
            break :blk gpa.allocator();
        },
        .ReleaseFast, .ReleaseSmall => std.heap.c_allocator,
    };
    const rng_seed: u64 = @intCast(std.time.nanoTimestamp());
    var prng = std.Random.DefaultPrng.init(rng_seed);

    // --- Init raylib ---
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
        .msaa_4x_hint = true,
    });
    rl.initWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Project Neon");
    rl.setTargetFPS(144);
    defer rl.closeWindow();

    // --- Init canvas ---
    const canvas: rl.RenderTexture2D = try rl.loadRenderTexture(CANVAS_WIDTH, CANVAS_HEIGHT);
    rl.setTextureWrap(canvas.texture, rl.TextureWrap.clamp);
    rl.setTextureFilter(canvas.texture, rl.TextureFilter.bilinear);

    // --- Init context ---
    var ctx = Context{
        .ecs = ECS.init(allocator),
        .allocator = allocator,
        .rng = prng.random(),
        .atlases = .init(.{
            .cube = .init("assets/gen_textures/atlases/cube_atlas.png", 96, 96),
            .roto = .init("assets/gen_textures/atlases/roto_atlas.png", 96, 96),
            .projectile = .init("assets/gen_textures/atlases/projectile_atlas.png", 96, 96),
        }),
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
        }),
        .temp = .{},
    };

    // // --- Init atlases ---
    // try ctx.atlases.put(.cube, TextureAtlas.init(
    //     "assets/gen_textures/atlases/cube_atlas.png",
    //     96,
    //     96,
    // ));
    // try ctx.atlases.put(.roto, TextureAtlas.init(
    //     "assets/gen_textures/atlases/roto_atlas.png",
    //     96,
    //     96,
    // ));
    // try ctx.atlases.put(.roto, TextureAtlas.init(
    //     "assets/gen_textures/atlases/projectile_atlas.png",
    //     96,
    //     96,
    // ));

    // // --- Init shaders ---
    // try ctx.shaders.put(.neon_sprite, try rl.loadShader(
    //     "assets/shaders/neon_sprite.vert",
    //     "assets/shaders/neon_sprite.frag",
    // ));
    // try ctx.shaders.put(.bloom, try rl.loadShader(
    //     null,
    //     "assets/shaders/bloom.frag",
    // ));
    // try ctx.shaders.put(.starfield, try rl.loadShader(
    //     null,
    //     "assets/shaders/starfield.frag",
    // ));

    // --- Init starfield shader ---
    {
        const shader = ctx.shaders.get(.starfield).?;
        const resolution = [2]f32{ CANVAS_WIDTH_F32, CANVAS_HEIGHT_F32 };
        const u_resolution = helpers.shaderUniform(shader, "u_resolution");
        rl.setShaderValue(shader, u_resolution, &resolution, .vec2);
    }
    // --- Temp ---
    _ = entity.player.spawn(&ctx.ecs, ctx.atlases.get(.cube).?, .init(400, 400));

    while (!rl.windowShouldClose()) {
        ctx.ecs.beginQuery();

        // --- Pre-draw update ---
        update(&ctx);

        // --- Canvas drawing ---
        rl.beginTextureMode(canvas);
        draw(&ctx);
        rl.endTextureMode();

        // --- Post-draw update ---
        updatePost(&ctx);

        ctx.ecs.endQuery();

        // ------ Drawing canvas to window ------
        {
            const bloom_shader = ctx.shaders.get(.bloom).?;

            rl.beginDrawing();
            rl.beginShaderMode(bloom_shader);

            const src = rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = CANVAS_WIDTH_F32,
                .height = -CANVAS_HEIGHT_F32,
            };
            const dest = rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = CANVAS_WIDTH_F32 * helpers.screenScaleX(CANVAS_WIDTH_F32),
                .height = CANVAS_HEIGHT_F32 * helpers.screenScaleY(CANVAS_HEIGHT_F32),
            };

            rl.drawTexturePro(
                canvas.texture,
                src,
                dest,
                rl.Vector2{ .x = 0, .y = 0 },
                0,
                rl.Color.white,
            );

            rl.endShaderMode();

            rl.drawFPS(0, 0);
            rl.endDrawing();
        }
    }
}

fn update(ctx: *Context) void {
    // --- Canvas mouse pos ---
    {
        const screen_mouse_pos = rl.getMousePosition();
        ctx.mouse_pos = .{
            .x = screen_mouse_pos.x / helpers.screenScaleX(CANVAS_WIDTH_F32),
            .y = screen_mouse_pos.y / helpers.screenScaleY(CANVAS_HEIGHT_F32),
        };
    }

    // --- Systems ---
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
    system.chaseEntity(ctx);
    system.spinCosmetic(ctx);
    system.updateDamageFlash(ctx);
    system.updateRingOverTLifetime(ctx);
    system.spinCosmeticAccelScaled(&ctx.ecs);
    system.playerRotateFacingMouseCosmetic(ctx);
    system.handleCollisions(ctx);
    system.applyMotionToTransform(&ctx.ecs);
    system.motionApplyDragFriction(&ctx.ecs);
}

fn draw(ctx: *Context) void {
    const game_time: f32 = @floatCast(rl.getTime());

    // --- Starfield shader ---
    {
        const shader = ctx.shaders.get(.starfield).?;
        const u_time = helpers.shaderUniform(shader, "u_time");
        rl.setShaderValue(shader, u_time, &game_time, .float);

        rl.beginShaderMode(shader);
        rl.drawRectangle(
            0,
            0,
            CANVAS_WIDTH,
            CANVAS_HEIGHT,
            rl.Color.black,
        );
        rl.endShaderMode();
    }

    system.drawNeonSprites(&ctx.ecs, ctx.shaders.get(.neon_sprite).?);
    system.drawLumenBar(&ctx.ecs);
    system.drawRingOverT(&ctx.ecs);

    // Debug drawing
    system.drawPlayerHealth(&ctx.ecs);
    system.drawNeonSpriteEntityCount(&ctx.ecs);

    // if (debug_settings.show_hurtboxes) {
    //     system.drawDebugHurtboxes(&ecs);
    // }
    // if (debug_settings.show_hitboxes) {
    //     system.drawDebugHitboxes(&ecs);
    // }
}

fn updatePost(ctx: *Context) void {
    system.oneTickHitbox(&ctx.ecs);
    // TODO: fix the death related logic, its a mess
    system.despawnOOBEntities(
        &ctx.ecs,
        CANVAS_WIDTH_F32,
        CANVAS_HEIGHT_F32,
        -300.0,
    );
    system.lifetimeDespawn(&ctx.ecs);
    system.zeroHealthDeath(&ctx.ecs, ctx.rng);
    system.onDeath(&ctx.ecs, ctx.rng);
}
