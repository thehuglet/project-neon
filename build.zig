const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ------- raylib-zig dependency
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib_mod = raylib_dep.module("raylib"); // zig binding
    const raygui_mod = raylib_dep.module("raygui"); // optional
    const raylib_artifact = raylib_dep.artifact("raylib"); // compiled ralib C library

    const exe = b.addExecutable(.{
        .name = "main",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            // .imports = &.{
            //
            // },
        }),
    });

    // Link the raylib library into your executable
    exe.linkLibrary(raylib_artifact);

    // Import modules so you can: const rl = @import("raylib");
    exe.root_module.addImport("raylib", raylib_mod);
    exe.root_module.addImport("raygui", raygui_mod);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
