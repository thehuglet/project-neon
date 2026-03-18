const std = @import("std");

const rl = @import("raylib");
const Color = rl.Color;

const components = @import("ecs/components.zig");
const Player = components.Player;
const Position = components.Position;
const Rotation = components.Rotation;
const Velocity = components.Velocity;
const ECS = @import("ecs/mod.zig").ECS;

const SCREEN_WIDTH = 1920;
const SCREEN_HEIGHT = 1080;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // ------ Raylib init ------
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
        .msaa_4x_hint = true,
    });
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Project Neon");
    rl.setTargetFPS(200);
    defer rl.closeWindow();

    // ------ ECS init ------
    var ecs = ECS.init(allocator);
    defer ecs.deinit();

    // TODO: move all this player and texture stuff out of here
    const texture = try rl.loadTexture("assets/textures/cube_0.png");

    // player definition
    const player = ecs.assignEntityId();
    ecs.addComponent(player, Player{});
    ecs.addComponent(player, Position{ .x = 500, .y = 500 });
    ecs.addComponent(player, Rotation{ .angle = 0 });

    const shader = try rl.loadShader(null, "assets/shaders/neon_sprite.fs");
    defer rl.unloadShader(shader);

    const canvas: rl.RenderTexture2D = try rl.loadRenderTexture(1920, 1080);
    rl.setTextureFilter(canvas.texture, rl.TextureFilter.bilinear);

    while (!rl.windowShouldClose()) {
        // ------ Game logic ------
        ecs.beginQuery();
        defer ecs.endQuery();

        // ------ Drawing to canvas ------
        rl.beginTextureMode(canvas);

        rl.clearBackground(Color.black);
        {
            var query = ecs.query(.{ Player, Position });
            while (query.next()) |item| {
                const pos = item.get(Position).?;

                const source_rec = rl.Rectangle{
                    .x = 0.0,
                    .y = 0.0,
                    .width = @floatFromInt(texture.width),
                    .height = @floatFromInt(texture.height),
                };

                const scale: f32 = 0.8;
                const dest_rec = rl.Rectangle{
                    .x = pos.x,
                    .y = pos.y,
                    .width = @as(f32, @floatFromInt(texture.width)) * scale,
                    .height = @as(f32, @floatFromInt(texture.height)) * scale,
                };

                const origin = rl.Vector2{
                    .x = dest_rec.width / 2,
                    .y = dest_rec.height / 2,
                };

                rl.beginShaderMode(shader);
                rl.drawTexturePro(texture, source_rec, dest_rec, origin, 0, Color.white);
                rl.endShaderMode();
            }
        }

        rl.endTextureMode();

        // ------ Drawing canvas to screen ------
        rl.beginDrawing();
        rl.clearBackground(Color.black);

        const screen_scale_x = @as(f32, @floatFromInt(rl.getScreenWidth())) / 1920.0;
        const screen_scale_y = @as(f32, @floatFromInt(rl.getScreenHeight())) / 1080.0;

        rl.drawTexturePro(canvas.texture, rl.Rectangle{ .x = 0, .y = 0, .width = 1920, .height = -1080 }, // flip Y
            rl.Rectangle{ .x = 0, .y = 0, .width = 1920 * screen_scale_x, .height = 1080 * screen_scale_y }, rl.Vector2{ .x = 0, .y = 0 }, 0, Color.white);

        rl.endDrawing();
    }
}

pub fn inputDirection() rl.Vector2 {
    var input_dir = rl.Vector2.zero();

    if (rl.isKeyDown(rl.KeyboardKey.w)) input_dir.y -= 1;
    if (rl.isKeyDown(rl.KeyboardKey.s)) input_dir.y += 1;
    if (rl.isKeyDown(rl.KeyboardKey.a)) input_dir.x -= 1;
    if (rl.isKeyDown(rl.KeyboardKey.d)) input_dir.x += 1;

    return rl.Vector2.normalize(input_dir);
}
