const std = @import("std");

pub const AllocatorInfo = struct {
    allocator: std.mem.Allocator,
    init: ?*const fn () anyerror!void,
    deinit: ?*const fn () anyerror!void,
};
