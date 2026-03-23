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

    pub fn deinit(self: *EntityIdPool, allocator: std.mem.Allocator) void {
        self.recycled.deinit(allocator);
    }

    pub fn assignEntityId(self: *EntityIdPool) usize {
        if (self.recycled.pop()) |id| {
            return id;
        }

        const id = self.next_id;
        self.next_id += 1;
        return id;
    }

    pub fn freeEntityId(self: *EntityIdPool, allocator: std.mem.Allocator, entity_id: usize) void {
        self.recycled.append(allocator, entity_id) catch @panic("OOM");
    }
};
