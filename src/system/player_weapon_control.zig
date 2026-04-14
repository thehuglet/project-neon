const Context = @import("context").Context;

const c = @import("component");

pub fn playerWeaponControl(ctx: *Context) void {
    var query = ctx.ecs.query(.{
        c.WeaponUseIntent,
    });
    while (query.next()) |item| {
        const use_intent: *c.WeaponUseIntent = item.get(c.WeaponUseIntent).?;
        const is_dashing: bool = ctx.ecs.hasComponent(item.entity_id, c.Dashing);
        const input_use_primary = ctx.player_input_state.use_primary_fire;
        const input_use_secondary = ctx.player_input_state.use_secondary_fire;

        use_intent.use_primary_fire = input_use_primary and !is_dashing;
        use_intent.use_secondary_fire = input_use_secondary and !is_dashing;
    }
}
