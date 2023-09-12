const api = @import("arch/api.zig").api;
const std = @import("std");

fn write(_: *anyopaque, bytes: []const u8) anyerror!usize {
    var possible_error: ?anyerror = null;
    if (api.terminal) |terminal| {
        var num: usize = 0;
        for (bytes) |b| {
            num += 1;
            terminal.writeChar(b) catch |e| {
                num -= 1;
                possible_error = e;
            };
        }
        return if (possible_error) |e| e else num;
    }
    return 0;
}

pub const writer = std.io.Writer(*anyopaque, anyerror, write){ .context = undefined };
