const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("mach-qoa", .{ .source_file = .{ .path = "src/lib.zig" } });

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });
    main_tests.main_pkg_path = ".";

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&b.addRunArtifact(main_tests).step);
}
