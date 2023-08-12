const std = @import("std");

const terminal = @import("terminal.zig");

pub fn main() void {
    if (!terminal.init()) @panic("Failed to initialize terminal!");
    terminal.set_color(.light_magenta, .cyan);
    terminal.write_string("Hello, world!\n");
    terminal.write_string("New line!");

    @panic("Reached end of main!");
}

pub fn halt() noreturn {
    while (true) {}
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    terminal.set_color(.red, .black);
    terminal.new_line();
    terminal.write_string("[PANIC] ");
    terminal.write_string(msg);
    _ = error_return_trace;
    _ = ret_addr;
    halt();
}
