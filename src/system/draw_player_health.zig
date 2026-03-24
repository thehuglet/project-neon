const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn drawPlayerHealth(ecs: *ECS) void {
    var query = ecs.query(.{
        c.Player,
        c.HealthLives,
    });
    while (query.next()) |item| {
        const health_lives: *c.HealthLives = item.get(c.HealthLives).?;

        var buf: [64]u8 = undefined;

        const text = std.fmt.bufPrintZ(&buf, "HP: {}", .{health_lives.lives}) catch unreachable;

        rl.drawText(text, 0, 22, 24, .white);
    }
}
