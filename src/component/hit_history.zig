const EntityId = @import("ecs").EntityId;

const MAX_HIT_HISTORY = 32;

pub const HitHistory = struct {
    keys: [MAX_HIT_HISTORY]EntityId =
        [_]EntityId{EntityId{ .index = 0, .generation = 0 }} ** MAX_HIT_HISTORY,
    used: [MAX_HIT_HISTORY]bool = [_]bool{false} ** MAX_HIT_HISTORY,

    pub fn add(h: *HitHistory, id: EntityId) void {
        var i = hash(id) % MAX_HIT_HISTORY;

        var probes: usize = 0;
        while (probes < MAX_HIT_HISTORY) : (probes += 1) {
            if (!h.used[i]) {
                h.used[i] = true;
                h.keys[i] = id;
                return;
            }

            if (h.keys[i] == id) {
                // Already exists
                return;
            }

            i = (i + 1) % MAX_HIT_HISTORY;
        }
    }

    pub fn contains(h: *const HitHistory, id: EntityId) bool {
        var i = hash(id) % MAX_HIT_HISTORY;

        var probes: usize = 0;
        while (probes < MAX_HIT_HISTORY and h.used[i]) : (probes += 1) {
            if (h.keys[i] == id) {
                return true;
            }
            i = (i + 1) % MAX_HIT_HISTORY;
        }
        return false;
    }

    fn hash(id: EntityId) u32 {
        return id.index ^ id.generation;
    }
};
