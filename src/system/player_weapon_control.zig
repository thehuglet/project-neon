const rl = @import("raylib");

const ECS = @import("ecs").ECS;
const c = @import("component");

pub fn playerWeaponControl(ecs: *ECS) void {
    var query = ecs.query(.{
        c.PlayerInput,
        c.WeaponUseIntent,
    });
    while (query.next()) |item| {
        const player_input: *c.PlayerInput = item.get(c.PlayerInput).?;
        const use_intent: *c.WeaponUseIntent = item.get(c.WeaponUseIntent).?;

        use_intent.use_primary_fire = player_input.use_primary_fire;
        use_intent.use_secondary_fire = player_input.use_secondary_fire;
    }
}
