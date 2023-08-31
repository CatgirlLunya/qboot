const memory_map = @import("memory_map.zig");
const memory = @import("../../../api/memory.zig");
const std = @import("std");
const divCeil = std.math.divCeil;

pub const Context = struct {
    base: [*]u8,
    length: u64,
};

var ctx: Context = undefined;

pub fn setPage(base: [*]u8, page: u64, used: bool) void {
    var page_byte = @as(u32, @intCast(@divFloor(page, 8)));
    if (used) {
        base[page_byte] |= (@as(u8, 1) << @as(u3, @intCast(page % 8)));
    } else {
        base[page_byte] &= ~(@as(u8, 1) << @as(u3, @intCast(page % 8)));
    }
}

pub fn init() !void {
    try memory_map.init();

    // Converts max RAM into how many bytes are needed to store a bitmap of pages, maximum possible RAM is 4 GB
    var ram = memory_map.memoryMap.usableMax();
    if (ram >= (1 << 32)) ram = (1 << 32) - 1;
    const pages = try divCeil(usize, @as(usize, @intCast(ram)), std.mem.page_size);
    const bytes_needed = try divCeil(u64, pages, 8);
    const memory_region = try memory_map.memoryMap.reserveSpace(bytes_needed);
    if (memory_region.base + memory_region.length > (1 << 32)) {
        return error.OutOfMemory;
    }

    // Turn allocated memory into pointers x86 can use
    const lower_base = @as(usize, @intCast(memory_region.base));
    ctx.base = @as([*]u8, @ptrFromInt(lower_base));
    ctx.length = memory_region.length;

    for (0..pages) |page| {
        setPage(ctx.base, page, true);
        if (page * std.mem.page_size < memory.MemoryBoundary) continue;
        for (0..memory_map.memoryMap.count) |e| {
            const entry = memory_map.memoryMap.entries[e];
            if (entry.memory_type != .usable) continue;
            // Need to make sure entire page is available, so if the entry base is past the page start we don't count it
            if (entry.base > page * std.mem.page_size) continue;
            if (entry.base + entry.length < ((page + 1) * std.mem.page_size - 1)) continue;
            setPage(ctx.base, page, false);
            break;
        }
    }
}
