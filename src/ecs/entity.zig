const std = @import("std");

pub const EntityIdPool = struct {
    next_id: usize,
    recycled: std.ArrayList(usize),

    pub fn init() EntityIdPool {
        return EntityIdPool{
            .next_id = 0,
            .recycled = std.ArrayList(usize).empty,
        };
    }

    pub fn assignEntityId(pool: *EntityIdPool) usize {
        if (pool.recycled.pop()) |id| {
            return id;
        }

        const id = pool.next_id;
        pool.next_id += 1;
        return id;
    }

    pub fn freeEntityId(pool: *EntityIdPool, entity_id: usize) void {
        _ = pool.recycled.append(entity_id);
    }
};
