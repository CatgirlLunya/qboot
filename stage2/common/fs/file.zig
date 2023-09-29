const GUID = @import("../guid.zig").GUID;
const std = @import("std");
const ext2 = @import("ext2.zig");

// TODO: Seriously refactor, use Zig OS api this time, use file descriptors as positions in arraylist?
pub const File = struct {
    const Self = @This();
    pub const ReadError = anyerror;
    pub const Reader = std.io.Reader(*Self, ReadError, read);

    read_fn: *const fn (self: *Self, dest: []u8) ReadError!usize,
    free_fn: *const fn (self: *File) anyerror!void,
    get_size_fn: *const fn (self: *File) anyerror!usize,
    // reader: Reader,

    pos: usize,
    extra: *anyopaque,

    pub fn reader(self: *File) Reader {
        return .{ .context = self };
    }

    fn read(self: *Self, dest: []u8) ReadError!usize {
        return self.read_fn(self, dest);
    }

    pub fn free(self: *Self) !void {
        return self.free_fn(self);
    }

    pub fn getSize(self: *Self) !usize {
        return self.get_size_fn(self);
    }
};
