const std = @import("std");

const rl = @import("raylib");

const components = @import("ecs/components.zig");
const Position = components.Position;
const Rotation = components.Rotation;
const Velocity = components.Velocity;
const ECS = @import("ecs/mod.zig").ECS;

// const addComponent = @import("ecs/mod.zig").addComponent;

// const Color = rl.Color;

// const component = @import("component.zig");
// const entity = @import("entity/mod.zig");
// const math = @import("math.zig");

// const SCREEN_WIDTH = 1600;
// const SCREEN_HEIGHT = 900;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var ecs = ECS.init(allocator);

    // Player definition
    const player = ecs.entity_id_pool.assign();
    ecs.addComponent(player, Position{ .x = 0, .y = 0 });
    ecs.addComponent(player, Rotation{ .angle = 0 });
    ecs.addComponent(player, Velocity{ .speed = 0 });

    // addComponent(&ecs, player, Position{ .x = 0, .y = 0 });

    // ecs.add_component(player, Component{ .Position = Position{ .x = 0, .y = 0 } });
    // try ecs.components.position.add_component(player, Position{ .x = 0, .y = 0 });
    // try ecs.components.position.add_component(player, Position{ .x = 0, .y = 0 });

    // rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Project Neon");

    // rl.setTargetFPS(200);
    // const player = ecs.entity_id_pool.assign();
    // const enemy = ecs.entity_id_pool.assign();

    // _ = try ecs.components.position.add_component(player, component.Position{ .x = 0, .y = 0 });
    // // _ = try ecs.components.velocity.add_component(player, component.Velocity{ .dx = 1, .dy = 0 });

    // _ = try ecs.components.position.add_component(enemy, component.Position{ .x = 10, .y = 5 });
    // _ = try ecs.components.velocity.add_component(enemy, component.Velocity{ .dx = -1, .dy = 0 });

    // for (ecs.components.position.data.items, 0..) |*pos, i| {
    //     const entity_id: u32 = ecs.components.position.entity_ids.items[i];
    //     std.debug.print("entity_id: {} | ({d}, {d})\n", .{ entity_id, pos.*.x, pos.*.y });
    // }

    // for (ecs.components.position.data.items, 0..) |*pos, i| {
    //     std.debug.print("({d}, {d})\n", .{ pos.*.x, pos.*.y });
    //     // std.debug.print("Entity {d}: Position = ({f}, {f})\n", .{ entity_id, pos.*.x, pos.*.y });
    // }

    // for (ecs.components.velocity.data.items, 0..) |*vel, i| {
    //     const entity_id = ecs.components.velocity.entity_ids.items[i];
    //     std.debug.print("Entity {d}: Velocity = ({f}, {f})\n", .{ entity_id, vel.*.dx, vel.*.dy });
    // }

    // const image = try rl.loadImage("assets/textures/cube_0.png");
    // const texture = try rl.loadTextureFromImage(image);

    // rl.unloadImage(image);

    // // De-initialization
    // defer rl.closeWindow();
    // defer rl.unloadTexture(texture);

    // var angle: f32 = 0;
    // var character_pos = rl.Vector2{
    //     .x = @as(f32, @floatFromInt(SCREEN_WIDTH)) / 2,
    //     .y = @as(f32, @floatFromInt(SCREEN_HEIGHT)) / 2,
    // };

    // const character_speed = 500.0;

    // while (!rl.windowShouldClose()) {
    //     const delta_time: f32 = rl.getFrameTime();
    //     const mouse_pos: rl.Vector2 = rl.getMousePosition();

    //     // ------ Game logic ------
    //     const movement_dir: rl.Vector2 = inputDirection();

    //     if (movement_dir.x != 0 or movement_dir.y != 0) {
    //         character_pos = rl.Vector2.add(
    //             character_pos,
    //             rl.Vector2.scale(movement_dir, character_speed * delta_time),
    //         );
    //     }

    //     const dir_to_mouse = math.direction(character_pos, mouse_pos);

    //     const target_angle = math.vec2ToAngle(dir_to_mouse);
    //     angle = math.lerpAngle(angle, target_angle, delta_time * 10.0);

    //     // ------ Drawing ------
    //     rl.beginDrawing();
    //     defer rl.endDrawing();

    //     rl.clearBackground(Color.black);

    //     const source_rec = rl.Rectangle{
    //         .x = 0.0,
    //         .y = 0.0,
    //         .width = @floatFromInt(texture.width),
    //         .height = @floatFromInt(texture.height),
    //     };

    //     const scale: f32 = 0.7;
    //     const dest_rec = rl.Rectangle{
    //         .x = character_pos.x,
    //         .y = character_pos.y,
    //         .width = @as(f32, @floatFromInt(texture.width)) * scale,
    //         .height = @as(f32, @floatFromInt(texture.height)) * scale,
    //     };

    //     const origin = rl.Vector2{
    //         .x = dest_rec.width / 2,
    //         .y = dest_rec.height / 2,
    //     };

    //     rl.drawTexturePro(texture, source_rec, dest_rec, origin, angle * math.RAD_TO_DEG, Color.white);
    // }
}

pub fn inputDirection() rl.Vector2 {
    var input_dir = rl.Vector2.zero();

    if (rl.isKeyDown(rl.KeyboardKey.w)) input_dir.y -= 1;
    if (rl.isKeyDown(rl.KeyboardKey.s)) input_dir.y += 1;
    if (rl.isKeyDown(rl.KeyboardKey.a)) input_dir.x -= 1;
    if (rl.isKeyDown(rl.KeyboardKey.d)) input_dir.x += 1;

    return rl.Vector2.normalize(input_dir);
}
