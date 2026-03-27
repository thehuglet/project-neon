const std = @import("std");

const EMPTY_COMPONENT_INDEX: u32 = 0xFFFFFFFF;

pub fn SparseComponentSet(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        data: std.ArrayList(T),
        entity_indices: std.ArrayList(u32),
        component_indices: std.ArrayList(u32),

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .data = .empty,
                .entity_indices = .empty,
                .component_indices = .empty,
            };
        }

        pub fn deinit(sparse_set: *Self) void {
            sparse_set.data.deinit(sparse_set.allocator);
            sparse_set.entity_indices.deinit(sparse_set.allocator);
            sparse_set.component_indices.deinit(sparse_set.allocator);
        }

        pub fn addComponent(sparse_set: *Self, entity_index: u32, component: T) void {
            if (sparse_set.hasComponent(entity_index)) {
                return;
            }

            const component_index = sparse_set.data.items.len;

            sparse_set.data.append(sparse_set.allocator, component) catch {
                @panic("OOM");
            };
            sparse_set.entity_indices.append(sparse_set.allocator, entity_index) catch {
                @panic("OOM");
            };

            const exceeds_capacity: bool = entity_index >= sparse_set.component_indices.items.len;
            if (exceeds_capacity) {
                const old_len = sparse_set.component_indices.items.len;
                sparse_set.component_indices.resize(sparse_set.allocator, entity_index + 1) catch {
                    @panic("OOM");
                };
                @memset(
                    sparse_set.component_indices.items[old_len..],
                    EMPTY_COMPONENT_INDEX,
                );
            }

            sparse_set.component_indices.items[entity_index] = @intCast(component_index);
        }

        pub fn hasComponent(sparse_set: *Self, entity_index: u32) bool {
            const entity_index_out_of_bounds: bool = entity_index >= sparse_set.component_indices.items.len;
            if (entity_index_out_of_bounds) {
                return false;
            }

            const dense_index = sparse_set.component_indices.items[entity_index];

            const dense_index_out_of_bounds: bool = dense_index >= sparse_set.data.items.len;
            if (dense_index_out_of_bounds) {
                return false;
            }

            return sparse_set.entity_indices.items[dense_index] == entity_index;
        }

        pub fn getComponent(sparse_set: *Self, entity_index: u32) ?*T {
            if (!sparse_set.hasComponent(entity_index)) {
                return null;
            }

            const dense_index = sparse_set.component_indices.items[entity_index];
            return &sparse_set.data.items[dense_index];
        }

        pub fn removeComponent(sparse_set: *Self, entity_index: u32) void {
            if (!sparse_set.hasComponent(entity_index)) {
                return;
            }

            const dense_index = sparse_set.component_indices.items[entity_index];
            const last_index = sparse_set.data.items.len - 1;

            if (dense_index != last_index) {
                sparse_set.data.items[dense_index] = sparse_set.data.items[last_index];
                sparse_set.entity_indices.items[dense_index] = sparse_set.entity_indices.items[last_index];

                const moved_entity_id = sparse_set.entity_indices.items[dense_index];
                sparse_set.component_indices.items[moved_entity_id] = dense_index;
            }

            _ = sparse_set.data.pop();
            _ = sparse_set.entity_indices.pop();

            sparse_set.component_indices.items[entity_index] = EMPTY_COMPONENT_INDEX;
        }
    };
}
