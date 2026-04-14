const Context = @import("context").Context;
const EntityId = @import("ecs").EntityId;

const c = @import("component");

pub fn setTargetToPlayer(ctx: *Context) void {
    // Grab target player EntityId
    const target = blk: {
        var query = ctx.ecs.query(.{
            c.Player,
        });
        const player_item = query.next() orelse return;
        break :blk player_item.entity_id;
    };

    // Store in components components
    {
        var query = ctx.ecs.query(.{
            c.TargetsPlayer,
        });
        while (query.next()) |item| {
            const targeting_entity: EntityId = item.entity_id;

            ctx.ecs.addComponent(targeting_entity, c.TargetedEntity{
                .entity_id = target,
            });
        }
    }
}
