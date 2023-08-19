// Just ignore this file, its super messy and not idiomatic but works

extern const bss_begin: usize;
extern const bss_end: usize;

const std = @import("std");
const main = @import("../../main.zig");
const writer = @import("../../writer.zig");

export fn _start() linksection(".entry") noreturn {
    const ptr: [*]u8 = @ptrFromInt(bss_begin);
    for (0..bss_end - bss_begin) |c| {
        ptr[c] = 0;
    }

    @call(.never_inline, main.main, .{});
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    main.panic(msg, error_return_trace, ret_addr);
}

pub const std_options = struct {
    pub fn logFn(comptime _: std.log.Level, comptime _: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
        writer.writer.print(format ++ "\n", args) catch unreachable;
    }

    pub const log_level = .info;
};
