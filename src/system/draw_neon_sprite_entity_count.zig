const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn drawNeonSpriteEntityCount(ecs: *ECS) void {
    var entity_count: u32 = 0;

    var query = ecs.query(.{
        c.NeonSprite,
    });
    while (query.next()) |_| {
        entity_count += 1;
    }

    var buf: [64]u8 = undefined;
    const text = std.fmt.bufPrintZ(&buf, "ENTITIES: {}", .{entity_count}) catch unreachable;

    rl.drawText(text, 0, 44, 24, .white);
}
