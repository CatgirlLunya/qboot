const std = @import("std");

const arch = @import("arch/arch.zig");
const writer = @import("writer.zig");
const testing = @import("testing.zig");
const terminal = arch.terminal;
const clock = arch.clock;

pub fn bmain() !void {
    terminal.init() catch unreachable; // If this fails I don't think anything else will work
    terminal.setColor(.light_magenta, .cyan);
    std.log.info("Entered stage 2 bootloader with initialized terminal!", .{});
    try arch.init();
    testing.div_by_zero();

    const current_time = try clock.getTime();
    std.log.info("Current Time: {}:{:0>2}:{:0>2}", .{ current_time.h, current_time.m, current_time.s });
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    terminal.setColor(.red, .black);
    std.log.err("[PANIC] {s}", .{msg});
    _ = error_return_trace;
    _ = ret_addr;
    while (true) asm volatile ("hlt");
}
