pub const terminal = @import("terminal.zig");
pub const clock = @import("clock.zig");
pub const memory = @import("memory.zig");
pub const allocator = @import("allocator.zig");
pub const keyboard = @import("keyboard.zig");
pub const disk = @import("disk.zig");
pub const jump = @import("jump.zig");

pub const API = struct {
    /// List of terminal interfaces that potentially have an init function, potentially have a setColor function, but have to have a writeChar function.
    /// On platforms with no terminal, initialization code here could involve initializing a framebuffer and a font.
    /// Each writeChar function could simply not do anything if you prefer to use one terminal interface over another
    terminals: ?[]const terminal.Terminal,
    /// Clock interface that must provide a getTime function. Optional.
    clock: ?clock.Clock,
    /// Memory Map to pass to OS. Required.
    memory: memory.MemoryInfo,
    /// Allocator for dynamic memory usage while in the bootloader, all memory allocated will be marked as a special type for the OS to know. Required.
    /// Memory map initialization will not be called before this, but if it is needed it can be done within the init function here
    allocator: allocator.AllocatorInfo,
    /// Keyboard interface that can read in key inputs, with an optional init and deinit function. Optional.
    keyboard: ?keyboard.KeyboardInfo,
    /// Disk interface that gives the bootloader the info for the kernel file, needed to boot an OS
    disk: disk.DiskInterface,
    /// Architecture specific initialization code, f.e. IDT on BIOS or excetpions on UEFI. Optional.
    init: ?*const fn () anyerror!void,
};
