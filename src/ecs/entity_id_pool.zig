const std = @import("std");

pub const EntityId = packed struct(u64) {
    index: u32,
    generation: u32,

    pub fn format(self: EntityId, writer: anytype) !void {
        try writer.print("EntityId{{ index: {}, generation: {} }}", .{ self.index, self.generation });
    }
};

pub const EntityIdPool = struct {
    allocator: std.mem.Allocator,
    recycled_indices: std.ArrayList(u32),
    generations: std.ArrayList(u32),
    alive_indices: std.DynamicBitSet,

    pub fn init(allocator: std.mem.Allocator) EntityIdPool {
        return EntityIdPool{
            .allocator = allocator,
            .recycled_indices = std.ArrayList(u32).empty,
            .generations = std.ArrayList(u32).empty,
            .alive_indices = std.DynamicBitSet.initEmpty(
                allocator,
                256,
            ) catch {
                @panic("OOM");
            },
        };
    }

    pub fn deinit(self: *EntityIdPool) void {
        self.recycled_indices.deinit(self.allocator);
        self.generations.deinit(self.allocator);
        self.alive_indices.deinit();
    }

    pub fn assign(self: *EntityIdPool) EntityId {
        const maybe_recycled_id: ?u32 = self.recycled_indices.pop();

        const index: u32 = if (maybe_recycled_id) |idx| idx else create_new_id: {
            const new_index: u32 = @intCast(self.generations.items.len);
            self.generations.append(self.allocator, 0) catch {
                @panic("OOM");
            };
            self.alive_indices.resize(new_index + 1, false) catch {
                @panic("OOM");
            };
            break :create_new_id new_index;
        };

        const generation = self.generations.items[index] + 1;
        self.generations.items[index] = generation;
        self.alive_indices.set(index);

        return EntityId{
            .index = index,
            .generation = generation,
        };
    }

    pub fn free(self: *EntityIdPool, entity_id: EntityId) void {
        if (!self.isAlive(entity_id)) {
            std.log.warn(
                "Attempted free on already freed EntityId(index={}, generation={}",
                .{ entity_id.index, entity_id.generation },
            );
            return;
        }

        self.recycled_indices.append(self.allocator, entity_id.index) catch {
            @panic("OOM");
        };
        self.alive_indices.unset(entity_id.index);
    }

    pub fn isAlive(self: *EntityIdPool, entity_id: EntityId) bool {
        if (entity_id.index >= self.generations.items.len) {
            std.debug.panic(
                "Attempted access to EntityId index {} which was never assigned",
                .{entity_id.index},
            );
        }

        const generation_matches: bool = entity_id.generation == self.generations.items[entity_id.index];
        return generation_matches and self.alive_indices.isSet(entity_id.index);
    }

    pub fn getGeneration(self: *EntityIdPool, entity_index: u32) u32 {
        if (entity_index >= self.generations.items.len) {
            std.debug.panic(
                "Attempted access to EntityId index {} which was never assigned",
                .{entity_index},
            );
        }

        return self.generations.items[entity_index];
    }
};
