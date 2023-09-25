const uefi = @import("std").os.uefi;
const file = @import("common").fs.file;

pub fn loadFile(path: []const u8) !file.File {
    _ = path;
    return error.OutOfMemory;
}
