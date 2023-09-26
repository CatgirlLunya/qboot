const uefi = @import("std").os.uefi;
const file = @import("common").fs.file;
const protocol = @import("wrapper/protocol.zig");

var root_dir: *uefi.protocols.FileProtocol = undefined;

pub fn init() !void {
    var fs_protocol = try protocol.loadProtocol(uefi.protocols.SimpleFileSystemProtocol);
    try fs_protocol.openVolume(&root_dir).err();
}

pub fn loadFile(path: []const u8) !file.File {
    var f: file.File = undefined;
    f.path = @constCast(path);
    var new_protocol: *uefi.protocols.FileProtocol = undefined;
    var buf = try uefi.pool_allocator.alloc(u16, path.len + 1);
    buf[path.len] = 0;
    for (path, 0..) |c, i| {
        buf[i] = c;
        if (c == '/') buf[i] = '\\';
    }

    try root_dir.open(
        &new_protocol,
        @ptrCast(buf.ptr),
        uefi.protocols.FileProtocol.efi_file_mode_read,
        0,
    ).err();

    var buffer_size: usize = 0;
    var buffer = try uefi.pool_allocator.alloc(u8, @sizeOf(uefi.protocols.FileInfo));

    new_protocol.getInfo(&uefi.protocols.FileInfo.guid, &buffer_size, buffer.ptr).err() catch {};
    buffer = try uefi.pool_allocator.realloc(buffer, buffer_size);
    try new_protocol.getInfo(&uefi.protocols.FileInfo.guid, &buffer_size, buffer.ptr).err();

    var info_struct = @as(*uefi.protocols.FileInfo, @alignCast(@ptrCast(buffer.ptr)));

    buffer_size = info_struct.file_size;
    f.contents = try uefi.pool_allocator.alloc(u8, info_struct.file_size);
    try new_protocol.read(&buffer_size, f.contents.ptr).err();

    try new_protocol.close().err();

    f.free = struct {
        pub fn free(self: *file.File) !void {
            uefi.pool_allocator.free(self.contents);
        }
    }.free;

    return f;
}
