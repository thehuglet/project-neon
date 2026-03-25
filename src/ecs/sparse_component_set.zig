const std = @import("std");

const EMPTY_COMPONENT_INDEX: u32 = 0xFFFFFFFF;

pub fn SparseComponentSet(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        data: std.ArrayList(T),
        entity_ids: std.ArrayList(usize),
        component_indices: std.ArrayList(usize),

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .data = .empty,
                .entity_ids = .empty,
                .component_indices = .empty,
            };
        }

        pub fn deinit(sparse_set: *Self) void {
            sparse_set.data.deinit(sparse_set.allocator);
            sparse_set.entity_ids.deinit(sparse_set.allocator);
            sparse_set.component_indices.deinit(sparse_set.allocator);
        }

        pub fn addComponent(sparse_set: *Self, entity_id: usize, component: T) void {
            if (sparse_set.hasComponent(entity_id)) {
                return;
            }

            const component_index: usize = sparse_set.data.items.len;

            sparse_set.data.append(sparse_set.allocator, component) catch @panic("Out of memory adding component");
            sparse_set.entity_ids.append(sparse_set.allocator, entity_id) catch @panic("Out of memory adding component");

            if (entity_id >= sparse_set.component_indices.items.len) {
                const old_len = sparse_set.component_indices.items.len;
                sparse_set.component_indices.resize(sparse_set.allocator, entity_id + 1) catch @panic("Out of memory adding component");
                @memset(sparse_set.component_indices.items[old_len..], EMPTY_COMPONENT_INDEX);
            }

            sparse_set.component_indices.items[entity_id] = @intCast(component_index);
        }

        pub fn hasComponent(sparse_set: *Self, entity_id: usize) bool {
            const entity_id_in_bounds: bool = entity_id < sparse_set.component_indices.items.len;
            if (!entity_id_in_bounds) {
                return false;
            }

            const dense_index = sparse_set.component_indices.items[entity_id];

            const dense_index_valid: bool = dense_index < sparse_set.data.items.len;
            if (!dense_index_valid) return false;

            const matches_entity: bool = sparse_set.entity_ids.items[dense_index] == entity_id;
            return matches_entity;
        }
        pub fn getComponent(sparse_set: *Self, entity_id: usize) ?*T {
            if (!sparse_set.hasComponent(entity_id)) {
                return null;
            }

            const dense_index: usize = sparse_set.component_indices.items[entity_id];
            return &sparse_set.data.items[dense_index];
        }

        pub fn removeComponent(sparse_set: *Self, entity_id: usize) void {
            if (!sparse_set.hasComponent(entity_id)) return;

            const dense_index: usize = sparse_set.component_indices.items[entity_id];
            const last_index: usize = sparse_set.data.items.len - 1;

            if (dense_index != last_index) {
                sparse_set.data.items[dense_index] = sparse_set.data.items[last_index];
                sparse_set.entity_ids.items[dense_index] = sparse_set.entity_ids.items[last_index];

                const moved_entity_id: usize = sparse_set.entity_ids.items[dense_index];
                sparse_set.component_indices.items[moved_entity_id] = dense_index;
            }

            _ = sparse_set.data.pop();
            _ = sparse_set.entity_ids.pop();

            sparse_set.component_indices.items[entity_id] = EMPTY_COMPONENT_INDEX;
        }
    };
}
