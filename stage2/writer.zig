const arch = @import("arch/arch.zig");
const std = @import("std");

fn write(_: *anyopaque, bytes: []const u8) !usize {
    return arch.terminal.writeString(bytes);
}

pub const writer = std.io.Writer(*anyopaque, anyerror, write){ .context = undefined };
