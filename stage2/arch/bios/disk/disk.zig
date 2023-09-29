const disk = @import("api").disk;
const memory = @import("api").memory;
const common = @import("common");
const gpt = common.gpt;
const file = common.fs.file;
const ext2 = common.fs.ext2;
const real_mode = @import("../asm/real_mode.zig");
const frame = @import("../asm/frame.zig");
const allocator = @import("../mm/pmm.zig");

const std = @import("std");

pub var disk_number: usize = undefined;
var fs: ext2.EXT2 = undefined;

const DiskPacket = packed struct {
    size: u8 = 0x10,
    unused: u8 = 0,
    sectors: u16,
    buffer_offset: u16,
    buffer_segment: u16,
    lba: u64,

    comptime {
        std.debug.assert(@sizeOf(@This()) == 0x10);
    }
};

const errors = error{
    DiskReadFail,
    BufferTooSmall,
    NoValidEntries,
};

pub fn readBytes(position: u64, bytes: usize, buffer: []u8) file.File.ReadError!void {
    const sector_size: u16 = 0x200;
    // Round bottom to lowest sector
    var bottom: u64 = @divFloor(position, sector_size) * sector_size;
    // Rounds top to highest sector
    var top: u64 = @divFloor((position + bytes) + (sector_size - 1), sector_size) * sector_size;
    var sectors: u64 = (top - bottom) / sector_size;

    // 32 sector buffer on the stack to ensure its in low memory, align(2) because this interrupt needs that for whatever reason
    var tmp_buf: [32 * 512]u8 align(2) = undefined;
    var buf_loc: usize = @intFromPtr(&tmp_buf);

    var it: usize = 0;
    while (sectors != 0) : (it += 1) {
        // Chunk size to read, max of 32 sectors but if not 32 sectors left just read the rest
        var chunk = @min(sectors, 32);

        var packet: DiskPacket = .{
            .sectors = chunk,
            .buffer_offset = @intCast(buf_loc % 16),
            .buffer_segment = @intCast(buf_loc / 16 + it * 2),
            .lba = bottom / 512 + it * 32,
        };

        var packet_segment: u32 = @intFromPtr(&packet) / 16;
        var packet_offset: u32 = @intFromPtr(&packet) % 16;

        var regs: frame.Frame = .{
            .eax = 0x4200,
            .edx = disk_number,
            .ds = packet_segment,
            .esi = packet_offset,
        };

        real_mode.biosInterrupt(0x13, &regs, &regs);

        if (regs.eflags & 0x1 == 1 or regs.eax & 0x00FF != 0) {
            std.log.err("EAX ERROR: {}, {}", .{ regs.eax, disk_number });
            return file.File.ReadError.ReadError;
        }

        sectors -= chunk;
        const offset_into_first_lba: usize = @intCast(position - bottom);
        if (it == 0) {
            // Put tmp_buf[offset..] into buffer[..end-offset]
            var end_index: usize = @intCast(@as(u64, chunk * sector_size) - offset_into_first_lba);
            @memcpy(buffer[0..end_index], tmp_buf[offset_into_first_lba .. chunk * sector_size]);
        } else {
            // Put tmp_buf[..end-offset] into buffer[it*32..]
            @memcpy(buffer[it * 512 * 32 ..], tmp_buf[0 .. chunk * sector_size - offset_into_first_lba]);
        }
    }
}

pub fn init() !void {
    disk_number = @as(*u8, @ptrFromInt(0x7C00 + 445)).*;

    // Allocate 33 LBAs worth of memory, to store header and all entries, skip past 0x200 because protective MBR
    var buf = try allocator.allocator.alloc(u8, 33 * 512);
    try readBytes(0x200, buf.len, buf);
    var table = try gpt.Table.readFromBinary(buf);
    var partition: gpt.Entry = undefined;
    var partition_index: usize = 0;
    partition.start_lba = 0;
    for (table.entries, 0..) |entry, i| {
        if (entry) |e| {
            if (e.type_guid.gpt_partition_type() == .linux_boot_partition) {
                partition = e;
                partition_index = i;
                break;
            }
        }
    }
    allocator.allocator.free(buf);
    if (partition.start_lba == 0) return error.NoValidEntries;
    std.log.debug("Found valid partition at index {}", .{partition_index});

    fs = try ext2.EXT2.init(allocator.allocator, readBytes, partition.start_lba * 512);
    std.log.debug("Verified EXT2 Filesystem!", .{});
}

/// In the BIOS implementation, only looks through the partition matching Linux /boot GUID
/// Partition should be formatted using ext2
pub fn loadFile(path: []const u8) !file.File {
    std.log.debug("Loading file {s}...", .{path[0]});
    return fs.loadFileFromPath(@constCast(path));
}

pub fn deinit() !void {
    fs.free();
}
