const std = @import("std");
const api = @import("arch").api;
const writer = @import("arch").writer;
const config = @import("common").config;
const elf = @import("common").elf;

pub export fn main() linksection(".entry") noreturn {
    kmain() catch |err| {
        std.log.err("Error from bmain: {!}", .{err});
    };
    // std.log.info("End of main!", .{});
    @panic("Reached end of main!");
}

pub fn kmain() !void {
    if (api.terminals) |terminals| {
        for (terminals) |terminal| {
            if (terminal.init) |init| try init();
            if (terminal.setColor) |setColor| try setColor(.white, .black);
        }
        std.log.info("Terminals initialized!", .{});
    }
    //
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
    var contents = try config_file.reader().readAllAlloc(api.allocator.allocator, @intCast(try config_file.getSize()));
    var cfg = try config.Config.readFromBin(api.allocator.allocator, contents);
    try config_file.free();
    api.allocator.allocator.free(contents);

    var kernel_file = try api.disk.loadFile(cfg.kernel_path);

    cfg.free(api.allocator.allocator);

    var kernel_elf = try elf.ElfFile.parse(&kernel_file);
    try @call(.never_tail, elf.ElfFile.loadIntoMemory, .{ &kernel_elf, &kernel_file });
    try kernel_elf.loadIntoMemory(&kernel_file);
    std.log.info("Jumping to {X}!!!", .{kernel_elf.header.entry});
    var buffer_there = @as([*]u8, @ptrFromInt(@as(usize, @intCast(kernel_elf.header.entry))))[0..32].*;
    std.log.info("Buffer There: {any}", .{buffer_there});
    try kernel_file.free();

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
    @as(*const fn () void, @ptrFromInt(@as(usize, @intCast(kernel_elf.header.entry))))();
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    if (api.terminals) |terminals| {
        for (terminals) |terminal| {
            if (terminal.setColor) |setColor| setColor(.red, .black) catch {};
        }
    }
    std.log.err("[PANIC] {s}", .{msg});
    if (error_return_trace) |e| {
        std.log.err("Stack Trace:", .{});
        for (e.instruction_addresses) |addr| {
            std.log.err("Address: {X}", .{addr});
        }
    }
    if (ret_addr) |r| {
        std.log.err("Ret Address: {X}", .{r});
    }

    while (true) asm volatile ("hlt");
}

pub const std_options = struct {
    pub fn logFn(comptime _: std.log.Level, comptime _: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
        writer.writer.print(format ++ "\n", args) catch unreachable;
    }

    pub const log_level = .info;

    // TODO: Refactoring, 0.2 update?
    // pub const os = struct {};
};
