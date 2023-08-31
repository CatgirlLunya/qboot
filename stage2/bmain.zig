const std = @import("std");

const api = @import("arch/api.zig").api;

pub fn bmain() !void {
    if (api.terminal) |terminal| {
        if (terminal.init) |init| try init();
        if (terminal.setColor) |setColor| try setColor(.white, .black);
        std.log.info("Terminal successfully initialized!", .{});
    }
    if (api.init) |init| {
        try init();
    }
    if (api.clock) |clock| {
        const current_time = try clock.getTime();
        std.log.info("Current Time: {}:{:0>2}:{:0>2}", .{ current_time.h, current_time.m, current_time.s });
    }
    if (api.allocator.init) |init| {
        try init();
    }
    try api.memory.init();
    try api.memory.map.minify();
    if (api.allocator.stop) |stop| {
        try stop();
    }
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    if (api.terminal) |terminal| {
        if (terminal.setColor) |setColor| setColor(.red, .black) catch {};
    }
    std.log.err("[PANIC] {s}", .{msg});
    _ = error_return_trace;
    _ = ret_addr;
    while (true) asm volatile ("hlt");
}
