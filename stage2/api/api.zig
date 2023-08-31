pub const terminal = @import("terminal.zig");
pub const clock = @import("clock.zig");
pub const memory = @import("memory.zig");
pub const allocator = @import("allocator.zig");

pub const API = struct {
    /// Terminal interface that potentially has an init function, potentially has a setColor function, but has to have a writeStr function. Optional
    /// On platforms with no terminal, initialization code here could involve initializing a framebuffer and a font.
    terminal: ?terminal.Terminal,
    /// Clock interface that must provide a getTime function. Optional.
    clock: ?clock.Clock,
    /// Memory Map to pass to OS. Required.
    memory: memory.MemoryInfo,
    /// Allocator for dynamic memory usage while in the bootloader, all memory allocated will be marked as a special type for the OS to know. Required.
    /// Memory map initialization will not be called before this, but if it is needed it can be done within the init function here
    allocator: allocator.AllocatorInfo,
    /// Architecture specific initialization code, f.e. IDT on BIOS or excetpions on UEFI. Optional.
    init: ?*const fn () anyerror!void,
};
