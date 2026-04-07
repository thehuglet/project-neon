const std = @import("std");

pub fn build(b: *std.Build) void {
    const allocator = std.heap.page_allocator;
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ------ Options ------
    const skip_atlas_gen = b.option(
        bool,
        "skip-atlas-gen",
        "Skip texture atlas generation",
    ) orelse false;

    // ------ Atlas generation ------
    const run_atlas_gen_cmd = b.addSystemCommand(&.{
        "cargo",
        "run",
        "--release",
        "--manifest-path",
        "tools/gen-blur-sprites/Cargo.toml",
        "atlas_config.toml",
    });
    run_atlas_gen_cmd.step.name = "Generating texture atlases";

    // ------- raylib-zig dependency ------
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib_mod = raylib_dep.module("raylib");
    // const raygui_mod = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    // ------ All-to-all global module mappings ------
    var modules = std.ArrayList(struct { name: []const u8, mod: *std.Build.Module }).empty;
    defer modules.deinit(allocator);

    const included_modules = [_]struct {
        name: []const u8,
        path: []const u8,
    }{
        .{ .name = "math", .path = "src/math.zig" },
        .{ .name = "helpers", .path = "src/helpers.zig" },
        .{ .name = "asset", .path = "src/asset.zig" },
        .{ .name = "weapon", .path = "src/weapon.zig" },
        .{ .name = "entity", .path = "src/entity/mod.zig" },
        .{ .name = "component", .path = "src/component/mod.zig" },
        .{ .name = "system", .path = "src/system/mod.zig" },
        .{ .name = "ecs", .path = "src/ecs/mod.zig" },
        .{ .name = "context", .path = "src/context.zig" },
    };

    for (included_modules) |info| {
        const mod = b.addModule(info.name, .{
            .root_source_file = b.path(info.path),
            .target = target,
            .optimize = optimize,
        });
        modules.append(allocator, .{ .name = info.name, .mod = mod }) catch @panic("OOM");
    }

    for (modules.items) |item_a| {
        for (modules.items) |item_b| {
            if (!std.mem.eql(u8, item_a.name, item_b.name)) {
                item_a.mod.addImport(item_b.name, item_b.mod);
            }
        }

        item_a.mod.addImport("raylib", raylib_mod);
        // item_a.mod.addImport("raygui", raygui_mod);
    }

    const exe = b.addExecutable(.{
        .name = "main",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    if (!skip_atlas_gen) {
        exe.step.dependOn(&run_atlas_gen_cmd.step);
    }
    exe.linkLibrary(raylib_artifact);

    for (modules.items) |item| {
        exe.root_module.addImport(item.name, item.mod);
    }
    exe.root_module.addImport("raylib", raylib_mod);
    // exe.root_module.addImport("raygui", raygui_mod);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
