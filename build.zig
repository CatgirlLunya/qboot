const std = @import("std");

fn here() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

pub fn build(b: *std.Build) void {
    var bios_stage1_target = CreateBIOSStage1Target(b, comptime here() ++ "/stage1");
    const test_step = b.step("bios", "Make the bios stage 1");
    test_step.dependOn(&bios_stage1_target.step);

    var uefi_target = CreateUEFITarget(b);
    SetupRunUEFI(b, uefi_target);
}

fn CreateUEFITarget(b: *std.Build) *std.Build.Step.InstallArtifact {
    const target = std.zig.CrossTarget{
        .cpu_arch = .x86_64,
        .abi = .msvc,
        .os_tag = .uefi,
    };

    // zig fmt: off
    const exe = b.addExecutable(.{
        .name = "BOOTX64",
        .root_source_file = .{ .path = "uefi/main.zig" },
        .target = target,
        .optimize = .ReleaseSmall,
    });
    // zig fmt: on

    var install = b.addInstallArtifact(exe, .{});
    install.dest_dir = .{ .custom = "uefi/EFI/BOOT/" };

    return install;
}

fn SetupRunUEFI(b: *std.Build, uefi_step: *std.Build.Step.InstallArtifact) void {
    const command_step = b.step("run-uefi", "Run the UEFI app in qemu");

    // zig fmt: off
    const run_step = b.addSystemCommand(&[_][]const u8{
        "qemu-system-x86_64",
        "-bios", b.fmt("{s}/uefi/OVMF.fd", .{b.build_root.path.?}),
        "-m", "256M",
        "-drive", b.fmt("format=raw,file=fat:rw:{s}", .{comptime here() ++ "/zig-out/uefi/"}),
    });
    // zig fmt: on

    run_step.step.dependOn(&uefi_step.step);
    command_step.dependOn(&run_step.step);
}

fn CreateBIOSStage1Target(b: *std.Build, location: []const u8) *std.Build.Step.Run {
    // zig fmt: off
    const run_step = b.addSystemCommand(&[_][]const u8{
        "nasm",
        b.fmt("{s}/boot.asm", .{location}),
        "-I", location,
        "-f", "bin",
        "-o", comptime here() ++ "/zig-out/stage1.bin"
    });
    // zig fmt: on

    return run_step;
}
