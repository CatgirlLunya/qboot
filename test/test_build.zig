const std = @import("std");

fn here() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

pub fn test_build(b: *std.Build) !*std.Build.Step {
    var target = std.zig.CrossTarget{
        .cpu_arch = .x86,
        .abi = .gnu,
        .os_tag = .freestanding,
    };

    const features = std.Target.x86.Feature;

    target.cpu_features_sub.addFeature(@intFromEnum(features.mmx));
    target.cpu_features_sub.addFeature(@intFromEnum(features.sse));
    target.cpu_features_sub.addFeature(@intFromEnum(features.sse2));
    target.cpu_features_sub.addFeature(@intFromEnum(features.avx));
    target.cpu_features_sub.addFeature(@intFromEnum(features.avx2));
    target.cpu_features_add.addFeature(@intFromEnum(features.soft_float));

    // zig fmt: off
    const exe = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = .{ .path = comptime here() ++ "/kernel/main.zig" },
        .target = target,
        .optimize = .ReleaseSafe,
    });
    // zig fmt: on
    exe.setLinkerScript(.{ .path = comptime here() ++ "/kernel/linker.ld" });

    var install = b.addInstallArtifact(exe, .{});
    install.dest_dir = .{ .custom = "kernel" };

    var copy_step = b.addSystemCommand(&.{ "cp", b.fmt("{s}/kernel/kernel.elf", .{b.install_path}), comptime here() ++ "/fs/" });

    var build_step = b.step("test-fs", "Compile the test kernel and generate the test file system");
    build_step.dependOn(&install.step);
    build_step.dependOn(&copy_step.step);

    return build_step;
}
