const std = @import("std");

const EMPTY_COMPONENT_INDEX: u32 = 0xFFFFFFFF;

pub fn SparseSet(comptime T: type) type {
    return struct {
        const Self = @This();

        data: std.ArrayList(T),
        entity_ids: std.ArrayList(u32),
        component_indices: std.ArrayList(u32),

        pub fn init() Self {
            return Self{
                .data = .empty,
                .entity_ids = .empty,
                .component_indices = .empty,
            };
        }

        pub fn deinit(self: *Self) void {
            self.data.deinit();
            self.entity_ids.deinit();
            self.component_indices.deinit();
        }

        pub fn add(self: *Self, entity_id: u32, component: T) !void {
            const component_index: usize = self.data.items.len;

            try self.data.append(component);
            try self.entity_ids.append(entity_id);

            if (entity_id >= self.component_indices.items.len)
                try self.component_indices.resize(entity_id + 1);

            self.component_indices.items[entity_id] = @intCast(component_index);
        }

        pub fn has_component(self: *Self, entity_id: u32) bool {
            // Out of bounds `entity_id` means the
            // entity can't have the component
            if (entity_id >= self.component_indices.items.len) {
                return false;
            }

            const dense_index: u32 = self.component_indices.items[entity_id];
            const valid_index: bool = dense_index < self.data.items.len;
            const matches_entity: bool = self.entity_ids.items[dense_index] == entity_id;

            return valid_index and matches_entity;
        }

        pub fn get_component(self: *Self, entity_id: u32) ?*T {
            if (!self.has_component(entity_id)) {
                return null;
            }

            const dense_index: u32 = self.component_indices.items[entity_id];
            return &self.data.items[dense_index];
        }

        pub fn remove_component(self: *Self, entity_id: u32) void {
            if (!self.has_component(entity_id)) {
                return;
            }

            const dense_index: u32 = self.component_indices.items[entity_id];
            const last_index: usize = self.data.items.len - 1;

            if (dense_index != last_index) {
                self.data.items[dense_index] = self.data.items[last_index];
                self.entity_ids.items[dense_index] = self.entity_ids.items[last_index];

                const moved_entity_id: u32 = self.entity_ids.items[dense_index];
                self.component_indices.items[moved_entity_id] = dense_index;
            }

            _ = self.data.items.pop();
            _ = self.entity_ids.items.pop();

            self.component_indices.items[entity_id] = EMPTY_COMPONENT_INDEX;
        }
    };
}
