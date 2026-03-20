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

    // ------ Raylib init ------
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
        .msaa_4x_hint = true,
    });
    rl.initWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Project Neon");
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
        .roto_atlas = asset.TextureAtlas.init(
            "assets/gen_textures/atlases/roto_atlas.png",
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
    const player = entity.player.spawn(&ecs, &assets, .init(400, 400));
    const roto_glow = entity.roto_glow.spawn(&ecs, &assets, .init(700, 400));
    const roto_charger = entity.roto_charger.spawn(&ecs, &assets, .init(1000, 600));

    ecs.addComponent(
        roto_glow,
        component.ChaseEntity{
            .entity_id = player,
            .turn_speed = 10.0,
        },
    );
    ecs.addComponent(
        roto_charger,
        component.ChaseEntity{
            .entity_id = player,
            .turn_speed = 10.0,
        },
    );

    // ------ Canvas init ------
    const canvas: rl.RenderTexture2D = try rl.loadRenderTexture(NATIVE_WIDTH, NATIVE_HEIGHT);
    rl.setTextureFilter(canvas.texture, rl.TextureFilter.bilinear);

    while (!rl.windowShouldClose()) {
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

        system.chaseEntity(&ecs);
        system.playerMovement(&ecs);

        system.playerRotateFacingMouseCosmetic(&ecs, mouse_pos);
        system.spinCosmetic(&ecs);

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
