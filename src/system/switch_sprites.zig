const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn switchSprites(ecs: *ECS) void {
    const scroll: f32 = rl.getMouseWheelMove();

    var query = ecs.query(.{
        c.SpriteSwitcher,
        c.NeonSprite,
    });
    while (query.next()) |item| {
        const neon_sprite: *c.NeonSprite = item.get(c.NeonSprite).?;

        if (scroll > 0.0) {
            // up
            neon_sprite.sprite_index += 1;
        } else if (scroll < 0.0) {
            // down
            neon_sprite.sprite_index -|= 1;
        }
    }
}
