const std = @import("std");
const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const entity = @import("entity");
const component = @import("component");
const system = @import("system");
const asset = @import("asset");

const WINDOW_WIDTH = 1600;
const WINDOW_HEIGHT = 900;

const NATIVE_WIDTH = 1920;
const NATIVE_HEIGHT = 1090;
const NATIVE_WIDTH_F32: f32 = @floatFromInt(NATIVE_WIDTH);
const NATIVE_HEIGHT_F32: f32 = @floatFromInt(NATIVE_HEIGHT);

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const seed: u64 = @intCast(std.time.nanoTimestamp());
    var prng = std.Random.DefaultPrng.init(seed);
    const rng = prng.random();

    // Temporary storage to avoid allocations
    var temp = struct {
        hurt_ids: std.ArrayList(usize) = .empty,
        hurt_positions: std.ArrayList(rl.Vector2) = .empty,
        hurt_radii: std.ArrayList(f32) = .empty,
        hurt_layers: std.ArrayList(u32) = .empty,

        pub fn clear(self: *@This()) void {
            self.hurt_ids.clearRetainingCapacity();
            self.hurt_positions.clearRetainingCapacity();
            self.hurt_radii.clearRetainingCapacity();
            self.hurt_layers.clearRetainingCapacity();
        }
    }{};
    defer {
        temp.hurt_ids.deinit(allocator);
        temp.hurt_positions.deinit(allocator);
        temp.hurt_radii.deinit(allocator);
        temp.hurt_layers.deinit(allocator);
    }

    // ------ Debug options ------
    var debug_hurtboxes = false;
    var debug_hitboxes = false;

    // ------ Raylib init ------
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
        .msaa_4x_hint = true,
    });
    rl.initWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Project Neon");
    rl.setTargetFPS(0);
    defer rl.closeWindow();

    // ------ ECS init ------
    var ecs = ECS.init(allocator);
    defer ecs.deinit();

    // ------ Assets init ------
    const assets = asset.Assets{
        .cube_atlas = asset.TextureAtlas.init(
            "assets/gen_textures/atlases/cube_atlas.png",
            96,
            96,
        ),
        .roto_atlas = asset.TextureAtlas.init(
            "assets/gen_textures/atlases/roto_atlas.png",
            96,
            96,
        ),
        .neon_sprite_shader = asset.NeonSpriteShader.init(
            "assets/shaders/neon_sprite.fs",
        ),
        .bloom_shader = asset.BloomShader.init(
            "assets/shaders/bloom.fs",
        ),
        .background_shader = asset.BackgroundShader.init(
            "assets/shaders/background.fs",
        ),
    };

    {
        const resolution = [2]f32{ NATIVE_WIDTH_F32, NATIVE_HEIGHT_F32 };
        rl.setShaderValue(
            assets.background_shader.shader,
            assets.background_shader.u_resolution,
            &resolution,
            .vec2,
        );
    }

    defer assets.cube_atlas.deinit();
    defer assets.neon_sprite_shader.deinit();

    // ------ Temp ------
    _ = entity.player.spawn(&ecs, &assets, .init(400, 400));

    // ------ Canvas init ------
    const canvas: rl.RenderTexture2D = try rl.loadRenderTexture(NATIVE_WIDTH, NATIVE_HEIGHT);
    rl.setTextureWrap(canvas.texture, rl.TextureWrap.clamp);
    rl.setTextureFilter(canvas.texture, rl.TextureFilter.bilinear);

    while (!rl.windowShouldClose()) {
        temp.clear();

        const current_time: f32 = @floatCast(rl.getTime());
        rl.setShaderValue(
            assets.background_shader.shader,
            assets.background_shader.u_time,
            &current_time,
            .float,
        );

        // ------ Debug toggles ------
        if (rl.isKeyPressed(rl.KeyboardKey.b)) {
            debug_hurtboxes = !debug_hurtboxes;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.n)) {
            debug_hitboxes = !debug_hitboxes;
        }

        const screen_scale_x = @as(f32, @floatFromInt(rl.getScreenWidth())) / NATIVE_WIDTH_F32;
        const screen_scale_y = @as(f32, @floatFromInt(rl.getScreenHeight())) / NATIVE_HEIGHT_F32;

        const screen_mouse_pos = rl.getMousePosition();
        const mouse_pos = rl.Vector2{
            .x = screen_mouse_pos.x / screen_scale_x,
            .y = screen_mouse_pos.y / screen_scale_y,
        };

        // ------ Game logic ------
        ecs.beginQuery();
        defer ecs.endQuery();

        // var hurtbox_count: usize = 0;
        // var hitbox_count: usize = 0;
        // var player_count: usize = 0;
        var e_count: i32 = 0;

        var q1 = ecs.query(.{component.NeonSprite});
        while (q1.next()) |_| e_count += 1;

        if (e_count == 1) {
            for (0..300) |_| {
                _ = entity.roto_charger.spawn(&ecs, rng, &assets, .init(1000, 600));
                _ = entity.roto_charger.spawn(&ecs, rng, &assets, .init(400, 200));
                _ = entity.roto_charger.spawn(&ecs, rng, &assets, .init(1300, 1000));
                _ = entity.roto_charger.spawn(&ecs, rng, &assets, .init(300, 1000));
                _ = entity.roto_charger.spawn(&ecs, rng, &assets, .init(500, 600));
            }
        }

        system.switchSprites(&ecs);
        system.setTargetToPlayer(&ecs);

        system.chaseEntity(&ecs);
        system.playerMovement(&ecs);

        // Cosmetic changes
        system.spinCosmetic(&ecs);
        system.playerRotateFacingMouseCosmetic(&ecs, mouse_pos);

        system.handleCollisions(
            &ecs,
            allocator,
            &temp.hurt_ids,
            &temp.hurt_positions,
            &temp.hurt_radii,
            &temp.hurt_layers,
        );

        // Physics end frame calculations
        system.applyMotionToTransform(&ecs);
        system.motionApplyDragFriction(&ecs);

        // ------ Drawing to canvas ------
        {
            rl.beginTextureMode(canvas);
            defer rl.endTextureMode();

            rl.beginShaderMode(assets.background_shader.shader);
            rl.drawRectangle(
                0,
                0,
                NATIVE_WIDTH,
                NATIVE_HEIGHT,
                rl.Color.black,
            );
            rl.endShaderMode();

            system.drawNeonSprite(&ecs, &assets.neon_sprite_shader);

            if (debug_hurtboxes) {
                system.drawDebugHurtboxes(&ecs);
            }
            if (debug_hitboxes) {
                system.drawDebugHitboxes(&ecs);
            }
        }

        // ------ Drawing canvas to screen ------
        {
            rl.beginDrawing();
            defer rl.endDrawing();

            {
                rl.beginShaderMode(assets.bloom_shader.shader);
                defer rl.endShaderMode();

                rl.drawTexturePro(
                    canvas.texture,
                    rl.Rectangle{
                        .x = 0,
                        .y = 0,
                        .width = NATIVE_WIDTH_F32,
                        .height = -NATIVE_HEIGHT_F32,
                    },
                    rl.Rectangle{
                        .x = 0,
                        .y = 0,
                        .width = NATIVE_WIDTH_F32 * screen_scale_x,
                        .height = NATIVE_HEIGHT_F32 * screen_scale_y,
                    },
                    rl.Vector2{
                        .x = 0,
                        .y = 0,
                    },
                    0,
                    rl.Color.white,
                );
            }
            rl.drawFPS(0, 0);
            drawEntityCount(0, 20, e_count, 20, rl.Color.white);
        }
    }
}

fn drawEntityCount(x: i32, y: i32, count: i32, fontSize: i32, color: rl.Color) void {
    var buf: [32]u8 = undefined; // enough for "999999 ENTITIES" + null
    const text = std.fmt.bufPrintZ(&buf, "{} ENTITIES", .{count}) catch return;
    rl.drawText(text, x, y, fontSize, color);
}
