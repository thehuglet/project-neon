const std = @import("std");

const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const c = @import("component");

pub fn setTargetToPlayer(ecs: *ECS) void {
    var player_query = ecs.query(.{c.Player});
    const player_item = player_query.next() orelse return;
    const player_entity_id = player_item.entity_id;

    var targetting_entity_query = ecs.query(.{
        c.TargetsPlayer,
    });
    while (targetting_entity_query.next()) |item| {
        const targetting_entity_id: EntityId = item.entity_id;

        ecs.addComponent(targetting_entity_id, c.TargetedEntity{
            .entity_id = player_entity_id,
        });
    }
}
