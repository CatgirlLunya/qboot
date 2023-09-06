const memory_map = @import("memory_map.zig");
const std = @import("std");

pub var fba: std.heap.FixedBufferAllocator = undefined;
pub const allocator: std.mem.Allocator = fba.allocator();

pub fn init() !void {
    try memory_map.init();

    // Only going to use 8 MB of ram hopefully
    var ram = memory_map.memoryMap.usableMax();
    if (ram < (1 << 27)) {
        return error.OutOfMemory;
    }

    // Reserves 8 MB
    const entry = try memory_map.memoryMap.reserveSpace(1 << 27);

    // Literally just converts entry.base into a [*]u8
    const base = @as([*]u8, @ptrFromInt(@as(usize, @intCast(entry.base))));

    fba = std.heap.FixedBufferAllocator.init(base[0..@as(usize, @intCast(entry.length))]);
}
