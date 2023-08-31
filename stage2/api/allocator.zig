const std = @import("std");

pub const AllocatorInfo = struct {
    allocator: std.mem.Allocator,
    init: ?*const fn () anyerror!void,
    stop: ?*const fn () anyerror!void,
};
