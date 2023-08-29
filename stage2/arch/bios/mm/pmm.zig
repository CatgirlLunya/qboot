const memory_map = @import("memory_map.zig");
pub fn init() !void {
    try memory_map.init();
}
