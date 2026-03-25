const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");
const a = @import("asset");

const math = @import("math");

pub fn spawn(ecs: *ECS, atlas: a.TextureAtlas, pos: rl.Vector2, facing_angle: f32) usize {
    const entity_id = ecs.assignEntityId();

    ecs.addComponent(entity_id, c.DespawnsWhenOOB{});
    ecs.addComponent(entity_id, c.Transform{
        .pos = pos,
        .rotation_rad = facing_angle * math.RAD_TO_DEG,
        .scale = 1.0,
    });
    ecs.addComponent(entity_id, c.Motion{
        .mass = 10.0,
        .friction = 0.0,
        .ignores_drag = true,
        .velocity = math.angleToVec2(facing_angle).scale(800.0),
    });
    ecs.addComponent(entity_id, c.NeonSprite{
        .atlas = atlas,
        .sprite_index = 0,
        .color = rl.Color.init(0, 200, 0, 255),
        .scale = 0.8,
    });
    ecs.addComponent(entity_id, c.Hitbox{
        .radius = 10.0,
        .mask = c.CollisionLayer.enemy,
    });

    return entity_id;
}
