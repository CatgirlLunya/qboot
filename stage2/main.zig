const std = @import("std");

const api = @import("arch/arch.zig").api;
const terminal = api.terminal;

pub export fn main() noreturn {
    if (!terminal.init()) @panic("Failed to initialize terminal!");
    terminal.setColor(.light_magenta, .cyan);
    terminal.writeString("Hello, world!\n");
    terminal.writeString("New line!");

    @panic("Reached end of main!"); // In a real bootloader, this should never happen; kernel should be run instead
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    terminal.setColor(.red, .black);
    terminal.newLine();
    terminal.writeString("[PANIC] ");
    terminal.writeString(msg);
    _ = error_return_trace;
    _ = ret_addr;
    while (true) asm volatile ("hlt");
}
