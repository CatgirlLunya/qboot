const memory = @import("memory.zig");
const common = @import("common");

pub const DiskInterface = struct {
    init: ?*const fn () anyerror!void,
    /// Returns a file matching one of the specified paths, returns the first one it finds of any
    /// Implementations may only allow a certain partition type or storage locations
    loadFile: *const fn (path: []const u8) anyerror!common.fs.file.File,
    deinit: ?*const fn () anyerror!void,
};
