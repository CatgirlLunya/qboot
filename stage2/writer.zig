const api = @import("arch/api.zig").api;
const std = @import("std");

fn write(_: *anyopaque, bytes: []const u8) anyerror!usize {
    if (api.terminal) |terminal| {
        return try terminal.writeStr(bytes);
    }
    return 0;
}

pub const writer = std.io.Writer(*anyopaque, anyerror, write){ .context = undefined };
