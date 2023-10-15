const std = @import("std");
const test_build = @import("test/test_build.zig");

fn here() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

pub fn build(b: *std.Build) !void {
    var bios_target = try CreateBIOSStage2Target(b);
    try SetupRunBIOS(b, bios_target);
    try SetupDebugBIOS(b, bios_target);

    var uefi_target = CreateUEFITarget(b);
    try SetupRunUEFI(b, uefi_target);
    try SetupPackageUEFI(b, uefi_target);

    var test_build_step = try test_build.test_build(b);
    uefi_target.dependOn(test_build_step);
    bios_target.dependOn(test_build_step);
}

const Errors = error{
    DependencyNotPresent,
};

const DependencyStep = struct {
    step: std.Build.Step,
    dependency: []const u8,
};

fn createDependencyStep(b: *std.Build, name: []const u8) !*DependencyStep {
    var step = try b.allocator.create(DependencyStep);
    step.*.step = std.Build.Step.init(.{
        .makeFn = checkDependency,
        .id = .custom,
        .name = b.fmt("checkDependency {s}", .{name}),
        .owner = b,
    });
    step.*.dependency = name;

    return step;
}

fn checkDependency(step: *std.Build.Step, _: *std.Progress.Node) !void {
    const self = @fieldParentPtr(DependencyStep, "step", step);
    const path = std.os.getenv("PATH").?;
    var split = std.mem.splitScalar(u8, path, ':');
    while (split.next()) |slice| {
        var dir = std.fs.openDirAbsolute(slice, .{}) catch {
            std.debug.print("Could not open directory {s}!", .{slice});
            continue;
        };
        dir.access(self.dependency, .{}) catch {
            continue;
        };
        return;
    }
    std.log.err("Could not find dependency {s}! Please install it and retry", .{self.dependency});
    return error.DependencyNotPresent;
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
        .root_source_file = .{ .path = comptime here() ++ "/stage2/main.zig" },
        .target = target,
        .optimize = .Debug,
        .main_pkg_path = .{.path = comptime here() ++ "/stage2/" },
    });
    // zig fmt: on

    const common_mod = b.createModule(.{
        .source_file = .{ .path = "stage2/common/common.zig" },
    });
    const api_mod = b.createModule(.{
        .source_file = .{ .path = "stage2/api/api.zig" },
        .dependencies = &.{
            .{ .name = "common", .module = common_mod },
        },
    });
    const arch_mod = b.createModule(.{
        .source_file = .{ .path = "stage2/arch/api.zig" },
        .dependencies = &.{
            .{ .name = "api", .module = api_mod },
            .{ .name = "common", .module = common_mod },
        },
    });

    exe.addModule("api", api_mod);
    exe.addModule("common", common_mod);
    exe.addModule("arch", arch_mod);

    var install = b.addInstallArtifact(exe, .{});
    install.dest_dir = .{ .custom = "uefi/EFI/BOOT/" };

    var copy_step = b.addSystemCommand(&.{ "cp", "-a", comptime here() ++ "/test/fs/.", b.fmt("{s}/uefi", .{b.install_path}) });

    const build_step = b.step("uefi", "Build the UEFI app");
    build_step.dependOn(&install.step);
    build_step.dependOn(&copy_step.step);

    return build_step;
}

fn SetupRunUEFI(b: *std.Build, uefi_step: *std.Build.Step) !void {
    const command_step = b.step("run-uefi", "Run the UEFI app in qemu");
    const dependency_step = try createDependencyStep(b, "qemu-system-x86_64");

    // zig fmt: off
    const run_step = b.addSystemCommand(&[_][]const u8{
        "qemu-system-x86_64",
        "-bios", b.fmt("{s}/stage2/arch/uefi/OVMF.fd", .{b.build_root.path.?}),
        "-m", "256M",
        "-smp", "4",
        "-rtc", "base=localtime",
        "-drive", b.fmt("format=raw,file=fat:rw:{s}", .{comptime here() ++ "/zig-out/uefi/"}),
    });
    // zig fmt: on

    run_step.step.dependOn(&dependency_step.step);
    run_step.step.dependOn(uefi_step);
    command_step.dependOn(&run_step.step);
}

fn SetupPackageUEFI(b: *std.Build, uefi_step: *std.Build.Step) !void {
    const command_step = b.step("package-uefi", "Package the UEFI bootloader into a hard disk image");
    const dd_dependency_step = try createDependencyStep(b, "dd");
    const parted_dependency_step = try createDependencyStep(b, "parted");
    const mformat_dependency_step = try createDependencyStep(b, "mformat");
    const mcopy_dependency_step = try createDependencyStep(b, "mcopy");
    const rm_dependency_step = try createDependencyStep(b, "rm");

    // zig fmt: off
    const run_step = b.addSystemCommand(&[_][]const u8{
        "zsh",
        comptime here() ++ "/scripts/make_uefi_disk.sh",
        comptime here() ++ "/zig-out/uefi/EFI",
        comptime here() ++ "/zig-out/uefi/"
    });
    // zig fmt: on
    run_step.step.dependOn(&dd_dependency_step.step);
    run_step.step.dependOn(&parted_dependency_step.step);
    run_step.step.dependOn(&mformat_dependency_step.step);
    run_step.step.dependOn(&mcopy_dependency_step.step);
    run_step.step.dependOn(&rm_dependency_step.step);
    run_step.step.dependOn(uefi_step);

    command_step.dependOn(&run_step.step);
}

fn CreateBIOSStage1Target(b: *std.Build, location: []const u8) !*std.Build.Step {
    const dependency_step = try createDependencyStep(b, "nasm");

    // zig fmt: off
    const run_step = b.addSystemCommand(&[_][]const u8{
        "nasm",
        b.fmt("{s}/boot.asm", .{location}),
        "-I", location,
        "-f", "bin",
        "-o", comptime here() ++ "/zig-out/bios/stage1.bin"
    });
    // zig fmt: on

    run_step.step.dependOn(&dependency_step.step);
    return &run_step.step;
}

fn CreateBIOSStage2Target(b: *std.Build) !*std.Build.Step {
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
    target.cpu_features_sub.addFeature(@intFromEnum(features.soft_float));
    // target.cpu_features_add.addFeature(@intFromEnum(features.soft_float));

    // zig fmt: off
    const exe = b.addExecutable(.{
        .name = "stage2.bin",
        .root_source_file = .{ .path = comptime here() ++ "/stage2/main.zig" },
        .target = target,
        .optimize = .ReleaseSafe,
        .main_pkg_path = .{.path = comptime here() ++ "/stage2/" },
    });
    // zig fmt: on
    exe.setLinkerScript(.{ .path = "stage2/linker.ld" });
    exe.addAssemblyFile(.{ .path = "stage2/arch/bios/asm/real_mode.S" });

    const common_mod = b.createModule(.{
        .source_file = .{ .path = "stage2/common/common.zig" },
    });
    const api_mod = b.createModule(.{
        .source_file = .{ .path = "stage2/api/api.zig" },
        .dependencies = &.{
            .{ .name = "common", .module = common_mod },
        },
    });
    const arch_mod = b.createModule(.{
        .source_file = .{ .path = "stage2/arch/api.zig" },
        .dependencies = &.{
            .{ .name = "api", .module = api_mod },
            .{ .name = "common", .module = common_mod },
        },
    });

    exe.addModule("api", api_mod);
    exe.addModule("common", common_mod);
    exe.addModule("arch", arch_mod);
    exe.code_model = .small;

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

    const dependency_step = try createDependencyStep(b, "objcopy");
    objcopy_step.step.dependOn(&dependency_step.step);
    objcopy_step.step.dependOn(&install.step);

    const stage1_step = try CreateBIOSStage1Target(b, comptime here() ++ "/stage1");

    const build_disk_step = b.addSystemCommand(&[_][]const u8{
        "zsh",
        comptime here() ++ "/scripts/make_bios_disk.sh", // Make disk script
        comptime here() ++ "/zig-out/bios", // Dir containing binaries
        comptime here() ++ "/test/fs", // Dir containing files to put into ext2 fs
    });

    const fdisk_dependency_step = try createDependencyStep(b, "fdisk");
    const dd_dependency_step = try createDependencyStep(b, "dd");

    build_disk_step.step.dependOn(stage1_step);
    build_disk_step.step.dependOn(&fdisk_dependency_step.step);
    build_disk_step.step.dependOn(&dd_dependency_step.step);
    build_disk_step.step.dependOn(&objcopy_step.step);

    var build_step = b.step("bios", "Build the BIOS disk image");
    build_step.dependOn(&build_disk_step.step);

    return build_step;
}

fn SetupRunBIOS(b: *std.Build, bios_step: *std.Build.Step) !void {
    const command_step = b.step("run-bios", "Run the BIOS disk in qemu");
    const dependency_step = try createDependencyStep(b, "qemu-system-x86_64");

    // zig fmt: off
    const command_str = &[_][]const u8{
        "qemu-system-x86_64",
        "-smp", "4",
        "-m", "256M",
        "-vga", "std",
        "-rtc", "base=localtime",
        // "-serial", "stdio",
        "-no-reboot",
        "-drive", b.fmt("format=raw,file={s}", .{comptime here() ++ "/zig-out/bios/disk.dd"}),
    };

    const run_step = b.addSystemCommand(command_str);
    // zig fmt: on

    run_step.step.dependOn(&dependency_step.step);
    run_step.step.dependOn(bios_step);
    command_step.dependOn(&run_step.step);
}

fn SetupDebugBIOS(b: *std.Build, bios_step: *std.Build.Step) !void {
    const command_step = b.step("debug-bios", "Debug the BIOS disk with bochs");
    const dependency_step = try createDependencyStep(b, "bochs");

    const run_step = b.addSystemCommand(&[_][]const u8{
        "bochs",
        "-q",
    });

    run_step.step.dependOn(&dependency_step.step);
    run_step.step.dependOn(bios_step);
    command_step.dependOn(&run_step.step);
}
