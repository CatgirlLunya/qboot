pub const exceptions = @import("exceptions.zig");

pub fn init() void {
    exceptions.init() catch unreachable;
}
