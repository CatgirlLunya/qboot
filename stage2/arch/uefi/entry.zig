pub const std = @import("std");

pub const bmain = @import("../../bmain.zig");
const writer = @import("arch").writer;

pub fn main() noreturn {
    bmain.bmain() catch |err| {
        std.log.err("Error from bmain: {!}", .{err});
    };
    @panic("Reached end of bmain!"); // In a real bootloader, this should never happen; kernel should be run instead
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    bmain.panic(msg, error_return_trace, ret_addr);
}

pub const std_options = struct {
    pub fn logFn(comptime _: std.log.Level, comptime _: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
        writer.writer.print(format ++ "\n", args) catch unreachable;
    }

    pub const log_level = .info;
};
