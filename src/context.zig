const ECS = @import("ecs").ECS;
const EntityId = @import("ecs").EntityId;
const ParticleSystem = @import("particle").ParticleSystem;
const GlGetTextureHandleFnPtr = @import("helpers").GlGetTextureHandleFnPtr;
const GlMakeTextureHandleResidentFnPtr = @import("helpers").GlMakeTextureHandleResidentFnPtr;

const std = @import("std");
const rl = @import("raylib");
const math = @import("math");
const enums = @import("enums");
const particle = @import("particle");

var glGetHandle: GlGetTextureHandleFnPtr = undefined;
var glMakeResident: GlMakeTextureHandleResidentFnPtr = undefined;

pub const CollisionLayer = packed struct {
    player: bool = false,
    enemy: bool = false,

    pub fn intersects(self: CollisionLayer, other: CollisionLayer) bool {
        return (@as(u2, @bitCast(self)) & @as(u2, @bitCast(other))) != 0;
    }
};

pub const TextureAtlas = struct {
    texture: rl.Texture2D,
    bindless_handle: u64,
    cell_width: i32,
    cell_height: i32,
    cols: i32,
    rows: i32,

    pub fn init(path: [:0]const u8, cell_width: i32, cell_height: i32) TextureAtlas {
        const tex = rl.loadTexture(path) catch |err| {
            std.debug.panic("Error loading atlas: {s}, (error: {})", .{ path, err });
        };
        const handle = glGetHandle(tex.id);
        glMakeResident(handle);
        const tex_width: i32 = @intCast(tex.width);
        const tex_height: i32 = @intCast(tex.height);

        const cols: i32 = @divTrunc(tex_width, cell_width);
        const rows: i32 = @divTrunc(tex_height, cell_height);
        return .{
            .texture = tex,
            .bindless_handle = handle,
            .cell_width = cell_width,
            .cell_height = cell_height,
            .cols = cols,
            .rows = rows,
        };
    }

    pub fn deinit(self: TextureAtlas) void {
        rl.unloadTexture(self.texture);
    }
};

/// Mirrors GPU layout.
pub const GpuTextureAtlas = extern struct {
    // --- 16 bytes ---
    handle_lo: u32, // 4
    handle_hi: u32, // 4
    grid_x: u32, // 4
    grid_y: u32, // 4
    // --- 16 bytes ---
    cell_w: f32, // 4
    cell_h: f32, // 4
    _pad0: u32, // 4
    _pad1: u32, // 4
};

pub const PlayerInputState = struct {
    move_up: bool,
    move_down: bool,
    move_left: bool,
    move_right: bool,
    dash: bool,
    use_primary_fire: bool,
    use_secondary_fire: bool,
};

pub const Context = struct {
    allocator: std.mem.Allocator,
    ecs: ECS,
    rng: std.Random,
    viewport_size: struct {
        width: i32,
        height: i32,
    },
    atlases: std.EnumMap(enums.AtlasId, TextureAtlas),
    gpu_atlases: std.EnumMap(enums.AtlasId, GpuTextureAtlas),
    shaders: std.EnumMap(enums.ShaderId, rl.Shader),
    particle_system: ParticleSystem,
    game_settings: struct {
        show_hurtboxes: bool,
        show_hitboxes: bool,
    },
    temp: struct {
        hurt_ids: std.ArrayList(EntityId),
        hurt_positions: std.ArrayList(rl.Vector2),
        hurt_radii: std.ArrayList(f32),
        hurt_layers: std.ArrayList(CollisionLayer),
    },
    mouse_pos: rl.Vector2 = math.VECTOR2_ZERO,
    player_input_state: PlayerInputState,

    pub fn deinit(self: *Context) void {
        // ECS
        self.ecs.deinit();

        // Atlases
        {
            var iter = self.atlases.iterator();
            while (iter.next()) |entry| {
                entry.value.deinit();
            }
        }

        // Shaders
        {
            var iter = self.shaders.iterator();
            while (iter.next()) |entry| {
                rl.unloadShader(entry.value.*);
            }
        }

        // Temp
        self.temp.hurt_ids.deinit(self.allocator);
        self.temp.hurt_positions.deinit(self.allocator);
        self.temp.hurt_radii.deinit(self.allocator);
        self.temp.hurt_layers.deinit(self.allocator);

        // Particles
        particle.deinit(&self.particle_system);
    }

    pub fn clearTemp(self: *Context) void {
        self.temp.hurt_ids.clearRetainingCapacity();
        self.temp.hurt_positions.clearRetainingCapacity();
        self.temp.hurt_radii.clearRetainingCapacity();
        self.temp.hurt_layers.clearRetainingCapacity();
    }
};

// This modifies the globals in this module but that's fine.
pub fn setupGlBindlessFnPtrs(get: GlGetTextureHandleFnPtr, make: GlMakeTextureHandleResidentFnPtr) void {
    glGetHandle = get;
    glMakeResident = make;
}

pub fn buildGpuTextureAtlas(atlas: TextureAtlas) GpuTextureAtlas {
    const handle_lo: u32 = @intCast(atlas.bindless_handle & 0xFFFFFFFF);
    const handle_hi: u32 = @intCast(atlas.bindless_handle >> 32);
    const tex_w = @as(f32, @floatFromInt(atlas.texture.width));
    const tex_h = @as(f32, @floatFromInt(atlas.texture.height));
    const cell_w = @as(f32, @floatFromInt(atlas.cell_width));
    const cell_h = @as(f32, @floatFromInt(atlas.cell_height));

    return .{
        .handle_lo = handle_lo,
        .handle_hi = handle_hi,
        .grid_x = @intCast(atlas.cols),
        .grid_y = @intCast(atlas.rows),
        .cell_w = cell_w / tex_w,
        .cell_h = cell_h / tex_h,
        ._pad0 = 0,
        ._pad1 = 0,
    };
}
