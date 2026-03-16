const std = @import("std");

pub const EntityIdPool = struct {
    next_id: u32,
    recycled: std.ArrayList(u32),

    pub fn init() EntityIdPool {
        return EntityIdPool{
            .next_id = 0,
            .recycled = std.ArrayList(u32).empty,
        };
    }

    pub fn assign(self: *EntityIdPool) u32 {
        if (self.recycled.pop()) |id| {
            return id;
        }

        const id = self.next_id;
        self.next_id += 1;
        return id;
    }

    pub fn destroy(self: *EntityIdPool, entity_id: u32) void {
        _ = self.recycled.append(entity_id);
    }
};
