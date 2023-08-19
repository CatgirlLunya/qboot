const std = @import("std");

fn here() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

pub fn build(b: *std.Build) void {
    var bios_target = CreateBIOSStage2Target(b);
    SetupRunBIOS(b, bios_target);
    SetupDebugBIOS(b, bios_target);

    var uefi_target = CreateUEFITarget(b);
    SetupRunUEFI(b, uefi_target);
}

fn CreateUEFITarget(b: *std.Build) *std.Build.Step {
    const target = std.zig.CrossTarget{
        .cpu_arch = .x86_64,
        .abi = .msvc,
        .os_tag = .uefi,
    };

    // zig fmt: off
    const exe = b.addExecutable(.{
        .name = "BOOTX64",
        .root_source_file = .{ .path = "stage2/main.zig" },
        .target = target,
        .optimize = .ReleaseSmall,
    });

    // zig fmt: on

    var install = b.addInstallArtifact(exe, .{});
    install.dest_dir = .{ .custom = "uefi/EFI/BOOT/" };

    const build_step = b.step("uefi", "Build the UEFI app");
    build_step.dependOn(&install.step);

    return &install.step;
}

fn SetupRunUEFI(b: *std.Build, uefi_step: *std.Build.Step) void {
    const command_step = b.step("run-uefi", "Run the UEFI app in qemu");

    // zig fmt: off
    const run_step = b.addSystemCommand(&[_][]const u8{
        "qemu-system-x86_64",
        "-bios", b.fmt("{s}/stage2/arch/uefi/OVMF.fd", .{b.build_root.path.?}),
        "-m", "256M",
        "-drive", b.fmt("format=raw,file=fat:rw:{s}", .{comptime here() ++ "/zig-out/uefi/"}),
    });
    // zig fmt: on

    run_step.step.dependOn(uefi_step);
    command_step.dependOn(&run_step.step);
}

fn CreateBIOSStage1Target(b: *std.Build, location: []const u8) *std.Build.Step {
    // zig fmt: off
    const run_step = b.addSystemCommand(&[_][]const u8{
        "nasm",
        b.fmt("{s}/boot.asm", .{location}),
        "-I", location,
        "-f", "bin",
        "-o", comptime here() ++ "/zig-out/bios/stage1.bin"
    });
    // zig fmt: on

    return &run_step.step;
}

fn CreateBIOSStage2Target(b: *std.Build) *std.Build.Step {
    var target = std.zig.CrossTarget{
        .cpu_arch = .x86,
        .abi = .none,
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
        .name = "stage2.bin",
        .root_source_file = .{ .path = comptime here() ++ "/stage2/arch/bios/entry.zig" },
        .target = target,
        .optimize = .ReleaseSmall,
        .main_pkg_path = .{.path = comptime here() ++ "/stage2/" },
    });
    // zig fmt: on
    exe.setLinkerScript(.{ .path = "stage2/linker.ld" });

    var install = b.addInstallArtifact(exe, .{});
    install.dest_dir = .{ .custom = "bios" };

    // zig fmt: off
    const objcopy_step = b.addSystemCommand(&[_][]const u8{
        "objcopy",
        "-O", "binary",
        comptime here() ++ "/zig-out/bios/stage2.bin",
        comptime here() ++ "/zig-out/bios/bootloader.bin"
    });
    // zig fmt: on

    objcopy_step.step.dependOn(&install.step);

    const stage1_step = CreateBIOSStage1Target(b, comptime here() ++ "/stage1");

    const build_disk_step = b.addSystemCommand(&[_][]const u8{
        "zsh",
        comptime here() ++ "/scripts/make_bios_disk.sh",
        comptime here() ++ "/zig-out/bios",
    });

    build_disk_step.step.dependOn(stage1_step);
    build_disk_step.step.dependOn(&objcopy_step.step);

    var build_step = b.step("bios", "Build the BIOS disk image");
    build_step.dependOn(&build_disk_step.step);

    return build_step;
}

fn SetupRunBIOS(b: *std.Build, bios_step: *std.Build.Step) void {
    const command_step = b.step("run-bios", "Run the BIOS disk in qemu");

    // zig fmt: off
    const run_step = b.addSystemCommand(&[_][]const u8{
        "qemu-system-x86_64",
        "-smp", "4",
        "-m", "256M",
        "-vga", "std",
        "-drive", b.fmt("format=raw,file={s}", .{comptime here() ++ "/zig-out/bios/disk.dd"}),
    });
    // zig fmt: on

    run_step.step.dependOn(bios_step);
    command_step.dependOn(&run_step.step);
}

fn SetupDebugBIOS(b: *std.Build, bios_step: *std.Build.Step) void {
    const command_step = b.step("debug-bios", "Debug the BIOS disk with bochs");

    const run_step = b.addSystemCommand(&[_][]const u8{
        "bochs",
        "-q",
    });

    run_step.step.dependOn(bios_step);
    command_step.dependOn(&run_step.step);
}
