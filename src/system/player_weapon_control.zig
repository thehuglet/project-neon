const Context = @import("context").Context;

const c = @import("component");

pub fn playerWeaponControl(ctx: *Context) void {
    var query = ctx.ecs.query(.{
        c.PlayerInput,
        c.WeaponUseIntent,
    });
    while (query.next()) |item| {
        const player_input: *c.PlayerInput = item.get(c.PlayerInput).?;
        const use_intent: *c.WeaponUseIntent = item.get(c.WeaponUseIntent).?;

        const is_dashing: bool = ctx.ecs.hasComponent(item.entity_id, c.Dashing);
        use_intent.use_primary_fire = player_input.use_primary_fire and !is_dashing;
        use_intent.use_secondary_fire = player_input.use_secondary_fire and !is_dashing;
    }
}
