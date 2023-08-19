const std = @import("std");

const arch = @import("arch/arch.zig");
const writer = @import("writer.zig");
const testing = @import("testing.zig");
const terminal = arch.terminal;
const idt = arch.idt;
const debug = arch.debug;
const frame = arch.frame;

pub export fn main() noreturn {
    if (!terminal.init()) @panic("Failed to initialize terminal!");
    terminal.setColor(.light_magenta, .cyan);
    std.log.info("Entered stage 2 bootloader with initialized terminal!", .{});
    std.log.info("New line!", .{});

    idt.init();

    const f = frame.getFrame();

    f.dump();
    debug.bochsBreak();

    testing.div_by_zero();

    @panic("Reached end of main!"); // In a real bootloader, this should never happen; kernel should be run instead
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    terminal.setColor(.red, .black);
    std.log.err("[PANIC] {s}", .{msg});
    _ = error_return_trace;
    _ = ret_addr;
    while (true) asm volatile ("hlt");
}
