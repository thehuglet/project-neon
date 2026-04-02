const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
// const EntityId = @import("ecs").EntityId;

const c = @import("component");
const a = @import("asset");

// const helpers = @import("helpers");
// const math = @import("math");

pub fn drawLumenBar(ecs: *ECS) void {
    var query = ecs.query(.{
        c.Player,
        c.Lumen,
    });
    while (query.next()) |item| {
        const lumen: *c.Lumen = item.get(c.Lumen).?;
        // const weapon_slots: *c.WeaponSlots = item.get(c.WeaponSlots).?;

        // TODO: add dividers based on secondary lumen drain
        // _ = weapon_slots;

        const x = 10;
        const y = 80;
        const width = 300;
        const height = 10;

        const lumen_max_amount: f32 = lumen.max_amount;
        const lumen_amount: f32 = lumen.amount;

        const t: f32 = std.math.clamp(
            lumen_amount / @max(lumen_max_amount, 0.000001),
            0.0,
            1.0,
        );

        const width_f32: f32 = @floatCast(width);
        const fill_width: i32 = @intFromFloat(width_f32 * t);

        rl.drawRectangle(
            x,
            y,
            width,
            height,
            .init(40, 40, 40, 127),
        );

        rl.beginScissorMode(x, y, fill_width, height);
        rl.drawRectangleGradientH(
            x,
            y,
            width,
            height,
            .init(100, 200, 255, 255),
            .init(100, 130, 255, 255),
        );
        rl.endScissorMode();
    }
}
