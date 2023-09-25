const GUID = @import("../guid.zig").GUID;

pub const File = struct {
    path: []u8,
    contents: []u8,

    free: *const fn (self: *File) anyerror!void,
};
