const rl = @import("raylib");

const EntityId = @import("ecs").EntityId;

pub const TargetedEntity = struct {
    entity_id: EntityId,
};
