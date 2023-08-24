pub const exceptions = @import("exceptions.zig");

pub fn init() !void {
    try exceptions.init();
}
