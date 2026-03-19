const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");
const a = @import("asset");

pub fn spawn(ecs: *ECS, assets: *const a.Assets, pos: rl.Vector2) void {
    const entity = ecs.assignEntityId();
    ecs.addComponent(entity, c.Player{});
    ecs.addComponent(entity, c.Transform{
        .pos = pos,
        .rotation_rad = 0.0,
        .scale = 1.0,
    });
    ecs.addComponent(entity, c.NeonSprite.init(
        assets.cube_atlas,
        0,
        rl.Color.init(100, 200, 255, 255),

        c.NeonSprite.Options{},
    ));
}
