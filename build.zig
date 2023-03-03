const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mainCompilation = b.addExecutable(.{
        .name = "aoc2022",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    mainCompilation.emit_docs = .emit;
    mainCompilation.install();

    const testsCompilation = b.addTest(.{
        .name = "tests",
        .root_source_file = .{ .path = "src/day11a.zig" },
        .target = target,
        .optimize = optimize
    });

    // Dependencies
    const mechaModule = b.createModule(.{
        .source_file = .{ .path = "lib/mecha/mecha.zig" }
    });
    mainCompilation.addModule("mecha", mechaModule);
    testsCompilation.addModule("mecha", mechaModule);

    const run_cmd = mainCompilation.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&testsCompilation.step);
}
