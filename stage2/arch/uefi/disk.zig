const uefi = @import("std").os.uefi;
const file = @import("common").fs.file;
const protocol = @import("wrapper/protocol.zig");

var root_dir: *uefi.protocols.FileProtocol = undefined;

pub fn init() !void {
    var fs_protocol = try protocol.loadProtocol(uefi.protocols.SimpleFileSystemProtocol);
    try fs_protocol.openVolume(&root_dir).err();
}

pub fn loadFile(path: []const u8) !file.File {
    var new_protocol: *uefi.protocols.FileProtocol = undefined;
    var buffer = try uefi.pool_allocator.alloc(u16, path.len + 1);
    buffer[path.len] = 0;
    for (path, 0..) |c, i| {
        buffer[i] = c;
        if (c == '/') buffer[i] = '\\';
    }

    try root_dir.open(
        @constCast(&new_protocol),
        @ptrCast(buffer.ptr),
        uefi.protocols.FileProtocol.efi_file_mode_read,
        0,
    ).err();
    uefi.pool_allocator.free(buffer);

    var f: file.File = .{
        .pos = 0,
        .read_fn = struct {
            pub fn read(ctx: *file.File, dest: []u8) !usize {
                if (try ctx.getSize() <= ctx.pos) return 0;
                var file_protocol: *uefi.protocols.FileProtocol = @alignCast(@ptrCast(ctx.extra));
                try file_protocol.seekableStream().seekTo(ctx.pos);
                var len = try file_protocol.reader().read(dest);
                ctx.pos += len;
                return len;
            }
        }.read,
        .get_size_fn = struct {
            pub fn getSize(ctx: *file.File) !usize {
                var file_protocol: *uefi.protocols.FileProtocol = @alignCast(@ptrCast(ctx.extra));
                // preserve the old file position
                var pos: u64 = undefined;
                var end_pos: u64 = undefined;
                try file_protocol.getPosition(&pos).err();
                // seek to end of file to get position = file size
                try file_protocol.setPosition(uefi.protocols.FileProtocol.efi_file_position_end_of_file).err();
                try file_protocol.getPosition(&end_pos).err();
                // restore the old position
                try file_protocol.setPosition(pos).err();
                // return the file size = position
                return end_pos;
            }
        }.getSize,
        .free_fn = struct {
            pub fn free(ctx: *file.File) !void {
                var file_protocol: *uefi.protocols.FileProtocol = @alignCast(@ptrCast(ctx.extra));
                try file_protocol.close().err();
            }
        }.free,
        .extra = new_protocol,
    };

    return f;
}
