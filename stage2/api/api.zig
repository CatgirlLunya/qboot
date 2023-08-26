pub const terminal = @import("terminal.zig");
pub const clock = @import("clock.zig");

pub const API = struct {
    /// Optional terminal interface that potentially has an init function, potentially has a setColor function, but has to have a writeStr function.
    /// On platforms with no terminal, initialization code here could involve initializing a framebuffer and a font
    terminal: ?terminal.Terminal,
    /// Clock interface that must provide a getTime function
    clock: ?clock.Clock,
    /// Architecture specific initialization code, i.e. IDT on BIOS or excetpions on UEFI
    init: ?*const fn () anyerror!void,
};
