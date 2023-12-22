const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exes = [_]*std.build.Step.Compile{
        b.addExecutable(.{
            .name = "curses_pong",
            .root_source_file = .{ .path = "src/pong.zig" },
            .target = target,
            .optimize = optimize,
        }),
        b.addExecutable(.{
            .name = "curses_tabs",
            .root_source_file = .{ .path = "src/tabs.zig" },
            .target = target,
            .optimize = optimize,
        }),
    };

    for (exes) |exe| {
        exe.linkLibC();
        exe.linkSystemLibrary("ncurses");
        b.installArtifact(exe);
    }
}
