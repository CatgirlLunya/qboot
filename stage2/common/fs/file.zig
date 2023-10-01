const GUID = @import("../guid.zig").GUID;
const std = @import("std");
const ext2 = @import("ext2.zig");

// TODO: Seriously refactor, use Zig OS api this time, use file descriptors as positions in arraylist?
pub const File = struct {
    pub const ReadError = anyerror;
    pub const Reader = std.io.Reader(*File, ReadError, read);
    pub const SeekableStream = std.io.SeekableStream(*File, anyerror, anyerror, seekTo, seekBy, getPos, getSize);

    read_fn: *const fn (self: *File, dest: []u8) ReadError!usize,
    free_fn: *const fn (self: *File) anyerror!void,
    get_size_fn: *const fn (self: *File) anyerror!usize,
    // reader: Reader,

    pos: u64,
    extra: *anyopaque,

    pub fn reader(self: *const File) Reader {
        return .{ .context = @constCast(self) };
    }

    pub fn seekableStream(self: *const File) SeekableStream {
        return .{ .context = @constCast(self) };
    }

    fn read(self: *File, dest: []u8) ReadError!usize {
        return self.read_fn(self, dest);
    }

    pub fn free(self: *File) !void {
        return self.free_fn(self);
    }

    pub fn seekTo(self: *File, pos: u64) !void {
        self.pos = pos;
    }

    pub fn seekBy(self: *File, pos: i64) !void {
        self.pos += pos;
    }

    pub fn getPos(self: *File) !u64 {
        return self.pos;
    }

    pub fn getSize(self: *File) !u64 {
        return @intCast(try self.get_size_fn(self));
    }
};
