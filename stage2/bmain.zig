const std = @import("std");
const api = @import("arch").api;

pub fn bmain() !void {
    if (api.terminals) |terminals| {
        for (terminals) |terminal| {
            if (terminal.init) |init| try init();
            if (terminal.setColor) |setColor| try setColor(.white, .black);
        }
        std.log.info("Terminals initialized!", .{});
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

    if (api.disk.init) |init| {
        try init();
        std.log.info("Disk initialized!", .{});
    }

    const cfg_file_locations = &.{ "/config.cfg", "/boot/config.cfg" };
    var config_file = try api.disk.loadFile(cfg_file_locations[0]);
    std.log.info("\nContents: \n{s}\n", .{config_file.contents});
    try config_file.free(&config_file);

    // Keyboard code for later:
    // std.log.info("Now you can type: ", .{});
    // while (true) {
    //     if (api.keyboard) |keyboard| {
    //         const key = keyboard.getInput();
    //         if (key) |k| {
    //             if (k.code.function == .escape) break;
    //             if (k.event_type == .released) continue;
    //             switch (k.code) {
    //                 .printable => |ch| if (api.terminal) |terminal| try terminal.writeChar(@intCast(ch)),
    //                 .function => {
    //                     asm volatile ("nop");
    //                 },
    //                 // .function => |func| std.log.info("Function: {x}", .{@as(u32, @intFromEnum(func))}),
    //             }
    //         }
    //     }
    // }
    // std.log.info("", .{});

    if (api.disk.deinit) |deinit| {
        try deinit();
        std.log.info("Disk de-initialized!", .{});
    }

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
    if (api.terminals) |terminals| {
        for (terminals) |terminal| {
            if (terminal.setColor) |setColor| setColor(.red, .black) catch {};
        }
    }
    std.log.err("[PANIC] {s}", .{msg});
    _ = error_return_trace;
    _ = ret_addr;
    while (true) asm volatile ("hlt");
}
