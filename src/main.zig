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

const WINDOW_WIDTH = 1280;
const WINDOW_HEIGHT = 720;

const NATIVE_WIDTH = 1920;
const NATIVE_HEIGHT = 1090;
const NATIVE_WIDTH_F32: f32 = @floatFromInt(NATIVE_WIDTH);
const NATIVE_HEIGHT_F32: f32 = @floatFromInt(NATIVE_HEIGHT);

pub fn main() !void {
    const gpa = std.heap.GeneralPurposeAllocator(.{
        .safety = builtin.mode == .Debug,
    }){};
    const allocator = gpa.allocator();

    var ctx = Context{
        .allocator = allocator,
        .rng = blk: {
            const seed: u64 = @intCast(std.time.nanoTimestamp());
            var prng = std.Random.DefaultPrng.init(seed);
            break :blk prng.random();
        },
        .atlases = .init(allocator),
    };

    // Init atlases
    try {
        ctx.atlases.put("cube", TextureAtlas.init(
            "assets/gen_textures/atlases/cube_atlas.png",
            96,
            96,
        ));
        ctx.atlases.put("roto", TextureAtlas.init(
            "assets/gen_textures/atlases/roto_atlas.png",
            96,
            96,
        ));
    };

    // // Temporary storage to avoid allocations
    // var temp = struct {
    //     hurt_ids: std.ArrayList(EntityId) = .empty,
    //     hurt_positions: std.ArrayList(rl.Vector2) = .empty,
    //     hurt_radii: std.ArrayList(f32) = .empty,
    //     hurt_layers: std.ArrayList(u32) = .empty,

    //     pub fn clear(self: *@This()) void {
    //         self.hurt_ids.clearRetainingCapacity();
    //         self.hurt_positions.clearRetainingCapacity();
    //         self.hurt_radii.clearRetainingCapacity();
    //         self.hurt_layers.clearRetainingCapacity();
    //     }
    // }{};
    // defer {
    //     temp.hurt_ids.deinit(allocator);
    //     temp.hurt_positions.deinit(allocator);
    //     temp.hurt_radii.deinit(allocator);
    //     temp.hurt_layers.deinit(allocator);
    // }

    // ------ Debug options ------
    var debug_settings = debug.DebugSettings{
        .show_hurtboxes = false,
        .show_hitboxes = false,
    };

    // ------ Raylib init ------
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
        .msaa_4x_hint = false,
    });
    rl.initWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Project Neon");
    rl.setTargetFPS(120);
    defer rl.closeWindow();

    // ------ ECS ------
    var ecs = ECS.init(allocator);
    defer ecs.deinit();

    // ------ Assets init ------
    // Texture atlases
    const asset_atlas_cube: asset.TextureAtlas = .init(
        "assets/gen_textures/atlases/cube_atlas.png",
        96,
        96,
    );
    const asset_atlas_roto: asset.TextureAtlas = .init(
        "assets/gen_textures/atlases/roto_atlas.png",
        96,
        96,
    );
    const asset_atlas_projectile: asset.TextureAtlas = .init(
        "assets/gen_textures/atlases/projectile_atlas.png",
        96,
        96,
    );
    // Shaders
    const asset_shader_neon_sprite: rl.Shader = try rl.loadShader(
        "assets/shaders/neon_sprite.vert",
        "assets/shaders/neon_sprite.frag",
    );
    const asset_shader_bg_starfield: rl.Shader = try rl.loadShader(
        null,
        "assets/shaders/bg_starfield.frag",
    );
    const asset_shader_bloom: rl.Shader = try rl.loadShader(
        null,
        "assets/shaders/bloom.frag",
    );

    defer {
        // Texture atlases
        asset.deinitAtlas(asset_atlas_cube);
        asset.deinitAtlas(asset_atlas_roto);
        asset.deinitAtlas(asset_atlas_projectile);
        // Shaders
        rl.unloadShader(asset_shader_neon_sprite);
        rl.unloadShader(asset_shader_bg_starfield);
        rl.unloadShader(asset_shader_bloom);
    }

    // ------ Canvas init ------
    const canvas: rl.RenderTexture2D = try rl.loadRenderTexture(NATIVE_WIDTH, NATIVE_HEIGHT);
    rl.setTextureWrap(canvas.texture, rl.TextureWrap.clamp);
    rl.setTextureFilter(canvas.texture, rl.TextureFilter.bilinear);

    // ------ Bg starfield shader uniform resolution setting ------
    {
        const resolution = [2]f32{ NATIVE_WIDTH_F32, NATIVE_HEIGHT_F32 };
        rl.setShaderValue(
            asset_shader_bg_starfield,
            helpers.getShaderUniformChecked(
                asset_shader_bg_starfield,
                "u_resolution",
            ),
            &resolution,
            .vec2,
        );
    }
    // ------ Temp ------
    _ = entity.player.spawn(&ecs, asset_atlas_cube, .init(400, 400));

    while (!rl.windowShouldClose()) {
        const game_time: f32 = @floatCast(rl.getTime());
        const screen_mouse_pos = rl.getMousePosition();
        const canvas_mouse_pos = rl.Vector2{
            .x = screen_mouse_pos.x / helpers.screenScaleX(NATIVE_WIDTH_F32),
            .y = screen_mouse_pos.y / helpers.screenScaleY(NATIVE_HEIGHT_F32),
        };

        temp.clear();

        ecs.beginQuery();
        defer ecs.endQuery();

        // ------ Bg starfield shader uniform time setting ------
        {
            rl.setShaderValue(
                asset_shader_bg_starfield,
                helpers.getShaderUniformChecked(
                    asset_shader_bg_starfield,
                    "u_time",
                ),
                &game_time,
                .float,
            );
        }

        // ------ Debug toggles ------
        debug.handleDebugHotkeys(&debug_settings);

        // ------ Game logic ------
        {
            system.playerInputs(&ecs);
            system.playerMovement(&ecs);
            system.playerDashInit(&ecs);
            system.playerWeaponControl(&ecs);
            system.setTargetToPlayer(&ecs);
            system.handleWeapons(
                &ecs,
                rng,
                canvas_mouse_pos,
                asset_atlas_projectile,
            );
            system.updateDash(&ecs);
            system.updateDashTrailGhost(&ecs);
            system.updateLifetime(&ecs);
            system.chaseEntity(&ecs);
            system.spinCosmetic(&ecs);
            system.updateDamageFlash(&ecs);
            system.updateRingOverTLifetime(&ecs);
            system.spinCosmeticAccelScaled(&ecs);
            system.playerRotateFacingMouseCosmetic(&ecs, canvas_mouse_pos);
            system.handleCollisions(
                &ecs,
                allocator,
                &temp.hurt_ids,
                &temp.hurt_positions,
                &temp.hurt_radii,
                &temp.hurt_layers,
            );

            // ------ DIRTY TESTING FACILITY ------
            {
                for (0..2) |_| {
                    if (rl.isKeyPressed(rl.KeyboardKey.v)) {
                        _ = entity.roto_charger.spawn(&ecs, rng, asset_atlas_roto, .init(1000, 600));
                        _ = entity.roto_charger.spawn(&ecs, rng, asset_atlas_roto, .init(400, 200));
                        _ = entity.roto_charger.spawn(&ecs, rng, asset_atlas_roto, .init(1300, 1000));
                        _ = entity.roto_charger.spawn(&ecs, rng, asset_atlas_roto, .init(300, 1000));
                        _ = entity.roto_charger.spawn(&ecs, rng, asset_atlas_roto, .init(500, 600));
                    }
                }
            }

            // Physics end frame calculations
            system.applyMotionToTransform(&ecs);
            system.motionApplyDragFriction(&ecs);
        }

        // ------ Drawing to canvas ------
        {
            rl.beginTextureMode(canvas);
            defer rl.endTextureMode();

            // rl.beginShaderMode(asset_shader_bg_starfield);
            rl.drawRectangle(
                0,
                0,
                NATIVE_WIDTH,
                NATIVE_HEIGHT,
                rl.Color.black,
            );
            // rl.endShaderMode();

            system.drawNeonSprites(&ecs, asset_shader_neon_sprite);
            system.drawLumenBar(&ecs);
            system.drawRingOverT(&ecs);

            // Debug drawing
            system.drawPlayerHealth(&ecs);
            system.drawNeonSpriteEntityCount(&ecs);

            if (debug_settings.show_hurtboxes) {
                system.drawDebugHurtboxes(&ecs);
            }
            if (debug_settings.show_hitboxes) {
                system.drawDebugHitboxes(&ecs);
            }
        }

        // ------ Post-drawing logic ------
        {
            system.oneTickHitbox(&ecs);
            system.zeroHealthDeath(&ecs, rng);
            system.despawnOOBEntities(
                &ecs,
                NATIVE_WIDTH_F32,
                NATIVE_HEIGHT_F32,
                100.0,
            );
            system.lifetimeDespawn(&ecs);
            system.onDeath(&ecs, rng);
        }

        // ------ Drawing canvas to screen ------
        {
            rl.beginDrawing();
            defer rl.endDrawing();

            rl.beginShaderMode(asset_shader_bloom);
            defer rl.endShaderMode();

            const src = rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = NATIVE_WIDTH_F32,
                .height = -NATIVE_HEIGHT_F32,
            };
            const dest = rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = NATIVE_WIDTH_F32 * helpers.screenScaleX(NATIVE_WIDTH_F32),
                .height = NATIVE_HEIGHT_F32 * helpers.screenScaleY(NATIVE_HEIGHT_F32),
            };

            rl.drawTexturePro(
                canvas.texture,
                src,
                dest,
                rl.Vector2{ .x = 0, .y = 0 },
                0,
                rl.Color.white,
            );

            rl.drawFPS(0, 0);
        }
    }
}
