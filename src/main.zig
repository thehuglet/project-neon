const std = @import("std");
const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const entity = @import("entity");
const component = @import("component");
const system = @import("system");
const asset = @import("asset");

const NATIVE_WIDTH = 1920;
const NATIVE_HEIGHT = 1080;
const NATIVE_WIDTH_F32: f32 = @floatFromInt(NATIVE_WIDTH);
const NATIVE_HEIGHT_F32: f32 = @floatFromInt(NATIVE_HEIGHT);

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // ------ Raylib init ------
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
        .msaa_4x_hint = true,
    });
    rl.initWindow(NATIVE_WIDTH, NATIVE_HEIGHT, "Project Neon");
    rl.setTargetFPS(200);
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
        .neon_sprite_shader = asset.NeonSpriteShader.init(
            "assets/shaders/neon_sprite.fs",
        ),
    };

    defer assets.cube_atlas.deinit();
    defer assets.neon_sprite_shader.deinit();

    // ------ Temp ------
    entity.player.spawn(&ecs, &assets, rl.Vector2.init(400, 400));

    // ------ Canvas init ------
    const canvas: rl.RenderTexture2D = try rl.loadRenderTexture(1920, 1080);
    rl.setTextureFilter(canvas.texture, rl.TextureFilter.bilinear);

    while (!rl.windowShouldClose()) {
        // ------ Game logic ------
        ecs.beginQuery();
        defer ecs.endQuery();

        system.playerMovement(&ecs);
        system.playerRotateFacingMouseCosmetic(&ecs);

        // ------ Drawing to canvas ------
        {
            rl.beginTextureMode(canvas);
            defer rl.endTextureMode();

            rl.clearBackground(rl.Color.black);

            system.drawNeonSprite(&ecs, &assets.neon_sprite_shader);
        }

        // ------ Drawing canvas to screen ------
        {
            rl.beginDrawing();
            defer rl.endDrawing();

            const screen_scale_x = @as(f32, @floatFromInt(rl.getScreenWidth())) / NATIVE_WIDTH_F32;
            const screen_scale_y = @as(f32, @floatFromInt(rl.getScreenHeight())) / NATIVE_HEIGHT_F32;

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
    }
}
