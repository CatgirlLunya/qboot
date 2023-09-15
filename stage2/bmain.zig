const std = @import("std");
const api = @import("arch/api.zig").api;

pub fn bmain() !void {
    if (api.terminal) |terminal| {
        if (terminal.init) |init| try init();
        if (terminal.setColor) |setColor| try setColor(.white, .black);
        std.log.info("Terminal initialized!", .{});
    }
    if (api.init) |init| {
        try init();
        std.log.info("Platform initialized!", .{});
    }
    if (api.allocator.init) |init| {
        try init();
        std.log.info("Allocator initialized!", .{});
    }

    if (api.keyboard) |keyboard| {
        if (keyboard.init) |init| {
            try init();
            std.log.info("Keyboard initialized!", .{});
        }
    }

    if (api.clock) |clock| {
        const current_time = try clock.getTime();
        std.log.info("Current Time: {}:{:0>2}:{:0>2}", .{ current_time.h, current_time.m, current_time.s });
    }

    std.log.info("Now you can type: ", .{});
    while (true) {
        if (api.keyboard) |keyboard| {
            const key = keyboard.getInput();
            if (key) |k| {
                if (k.code.function == .escape) break;
                if (k.event_type == .released) continue;
                switch (k.code) {
                    .printable => |ch| if (api.terminal) |terminal| try terminal.writeChar(@intCast(ch)),
                    .function => {},
                    // .function => |func| std.log.info("Function: {x}", .{@as(u32, @intFromEnum(func))}),
                }
            }
        }
    }
    std.log.info("", .{});

    if (api.allocator.deinit) |deinit| {
        try deinit();
        std.log.info("Allocator de-initialized!", .{});
    }

    if (api.keyboard) |kb| {
        if (kb.deinit) |deinit| {
            try deinit();
            std.log.info("Keyboard de-initialized!", .{});
        }
    }
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    if (api.terminal) |terminal| {
        if (terminal.setColor) |setColor| setColor(.red, .black) catch {};
    }
    std.log.err("[PANIC] {s}", .{msg});
    _ = error_return_trace;
    _ = ret_addr;
    if (api.terminal) |terminal| {
        if (terminal.setColor) |setColor| setColor(.white, .black) catch {};
    }
    while (true) asm volatile ("hlt");
}
