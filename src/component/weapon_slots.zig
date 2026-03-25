const weapon = @import("weapon");

pub const WeaponSlots = struct {
    selected_slot: usize = 0,
    slots: [2]?weapon.WeaponInstance,
};
