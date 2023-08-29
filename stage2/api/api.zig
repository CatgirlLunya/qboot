pub const terminal = @import("terminal.zig");
pub const clock = @import("clock.zig");
pub const memory = @import("memory.zig");

pub const API = struct {
    /// Optional terminal interface that potentially has an init function, potentially has a setColor function, but has to have a writeStr function.
    /// On platforms with no terminal, initialization code here could involve initializing a framebuffer and a font
    terminal: ?terminal.Terminal,
    /// Optional clock interface that must provide a getTime function
    clock: ?clock.Clock,
    /// Memory Map to pass to OS, required
    memory: memory.MemoryInfo,
    /// Optional architecture specific initialization code, f.e. IDT on BIOS or excetpions on UEFI
    init: ?*const fn () anyerror!void,
};
