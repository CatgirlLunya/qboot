const api = @import("api.zig").api;
const std = @import("std");

fn write(_: *anyopaque, bytes: []const u8) anyerror!usize {
    var possible_error: ?anyerror = null;
    if (api.terminals) |terminals| {
        var num: usize = 0;
        for (terminals) |terminal| {
            for (bytes) |b| {
                num += 1;
                terminal.printChar(b) catch |e| {
                    num -= 1;
                    possible_error = e;
                };
            }
            if (possible_error) |e| return e;
        }
        return bytes.len;
    }
    return 0;
}

pub const writer = std.io.Writer(*anyopaque, anyerror, write){ .context = undefined };
