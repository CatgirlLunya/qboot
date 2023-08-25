const std = @import("std");

fn here() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

pub fn build(b: *std.Build) !void {
    var bios_target = try CreateBIOSStage2Target(b);
    try SetupRunBIOS(b, bios_target);
    try SetupDebugBIOS(b, bios_target);

    var uefi_target = CreateUEFITarget(b);
    try SetupRunUEFI(b, uefi_target);
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
        .root_source_file = .{ .path = comptime here() ++ "/stage2/arch/uefi/entry.zig" },
        .target = target,
        .optimize = .ReleaseSmall,
        .main_pkg_path = .{.path = comptime here() ++ "/stage2/" },
    });

    // zig fmt: on

    var install = b.addInstallArtifact(exe, .{});
    install.dest_dir = .{ .custom = "uefi/EFI/BOOT/" };

    const build_step = b.step("uefi", "Build the UEFI app");
    build_step.dependOn(&install.step);

    return &install.step;
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
    exe.addAssemblyFile(.{ .path = "stage2/arch/bios/asm/real_mode.S" });

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
        comptime here() ++ "/scripts/make_bios_disk.sh",
        comptime here() ++ "/zig-out/bios",
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
