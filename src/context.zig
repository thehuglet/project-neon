const std = @import("std");
const rl = @import("raylib");
const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const math = @import("math");
const enums = @import("enums");

pub const CollisionLayer = packed struct {
    player: bool = false,
    enemy: bool = false,
};

pub const GameSettings = struct {
    show_hurtboxes: bool,
    show_hitboxes: bool,
};

pub const TextureAtlas = struct {
    texture: rl.Texture2D,
    cell_width: i32,
    cell_height: i32,

    pub fn init(path: [:0]const u8, cell_width: i32, cell_height: i32) TextureAtlas {
        return .{
            .texture = rl.loadTexture(path) catch |err| {
                std.debug.panic(
                    "Error loading atlas: {s}, (error: {})",
                    .{ path, err },
                );
            },
            .cell_width = cell_width,
            .cell_height = cell_height,
        };
    }

    pub fn deinit(self: TextureAtlas) void {
        rl.unloadTexture(self.texture);
    }
};

pub const Context = struct {
    allocator: std.mem.Allocator,
    ecs: ECS,
    rng: std.Random,
    atlases: std.EnumMap(enums.AtlasId, TextureAtlas),
    shaders: std.EnumMap(enums.ShaderId, rl.Shader),
    game_settings: GameSettings = .{
        .show_hurtboxes = false,
        .show_hitboxes = false,
    },
    temp: struct {
        hurt_ids: std.ArrayList(EntityId) = .empty,
        hurt_positions: std.ArrayList(rl.Vector2) = .empty,
        hurt_radii: std.ArrayList(f32) = .empty,
        hurt_layers: std.ArrayList(u32) = .empty,
    },
    mouse_pos: rl.Vector2 = math.VECTOR2_ZERO,
    // window_mouse_pos: rl.Vector2 = .zero(),

    pub fn deinit(self: *Context) void {
        // ECS
        self.ecs.deinit();

        // Atlases
        {
            var iter = self.atlases.iterator();
            while (iter.next()) |entry| {
                entry.value_ptr.deinit();
            }
        }

        // Shaders
        {
            var iter = self.shaders.iterator();
            while (iter.next()) |entry| {
                rl.unloadShader(entry.value_ptr.*);
            }
        }

        // Temp
        self.temp.hurt_ids.deinit(self.allocator);
        self.temp.hurt_positions.deinit(self.allocator);
        self.temp.hurt_radii.deinit(self.allocator);
        self.temp.hurt_layers.deinit(self.allocator);
    }

    pub fn clearTemp(self: *Context) void {
        self.temp.hurt_ids.clearRetainingCapacity();
        self.temp.hurt_positions.clearRetainingCapacity();
        self.temp.hurt_radii.clearRetainingCapacity();
        self.temp.hurt_layers.clearRetainingCapacity();
    }
};
