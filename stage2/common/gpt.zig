const std = @import("std");
const GUID = @import("guid.zig").GUID;

pub const block_size = 512;

const crc = std.hash.Crc32;

pub const GptPartitionType = enum {
    unused,
    efi_system,
    bios_boot,
    linux_boot_partition,
    unknown,
};

pub const Header = struct {
    signature: u64,
    revision: u32,
    size: u32,
    crc32: u32,
    reserved: u32,
    header_lba: u64,
    alternate_header_lba: u64,
    first_usable_block: u64,
    last_usable_block: u64,
    disk_guid: GUID,
    gpt_partion_entry_array_lba: u64,
    partition_entries: u32,
    partition_entry_size: u32,
    partition_array_crc32: u32,

    pub fn readFromBinary(bin: []u8) Header {
        var header: Header = undefined;
        header.signature = std.mem.readIntLittle(u64, bin[0..8]);
        header.revision = std.mem.readIntLittle(u32, bin[8..12]);
        header.size = std.mem.readIntLittle(u32, bin[12..16]);
        header.crc32 = std.mem.readIntLittle(u32, bin[16..20]);
        header.header_lba = std.mem.readIntLittle(u64, bin[24..32]);
        header.alternate_header_lba = std.mem.readIntLittle(u64, bin[32..40]);
        header.first_usable_block = std.mem.readIntLittle(u64, bin[40..48]);
        header.last_usable_block = std.mem.readIntLittle(u64, bin[48..56]);
        header.disk_guid = GUID.readFromBinary(bin[56..72]);
        header.gpt_partion_entry_array_lba = std.mem.readIntLittle(u64, bin[72..80]);
        header.partition_entries = std.mem.readIntLittle(u32, bin[80..84]);
        header.partition_entry_size = std.mem.readIntLittle(u32, bin[84..88]);
        header.partition_array_crc32 = std.mem.readIntLittle(u32, bin[88..92]);
        return header;
    }

    pub fn valid(header: *Header) bool {
        // TODO: CRC32
        return header.signature == 0x5452415020494645;
    }

    comptime {
        std.debug.assert(@sizeOf(@This()) == 0x5C);
    }
};

pub const Entry = struct {
    type_guid: GUID,
    part_guid: GUID,
    start_lba: u64,
    end_lba: u64,
    attribs: u64,
    name: [72]u8,

    pub fn readFromBinary(bin: []u8) Entry {
        var entry: Entry = undefined;
        entry.type_guid = GUID.readFromBinary(bin[0..16]);
        entry.part_guid = GUID.readFromBinary(bin[16..32]);
        entry.start_lba = std.mem.readIntLittle(u64, bin[32..40]);
        entry.end_lba = std.mem.readIntLittle(u64, bin[40..48]);
        entry.attribs = std.mem.readIntLittle(u64, bin[48..56]);
        @memcpy(&entry.name, bin[56..128]);
        return entry;
    }
};

const errors = error{
    InvalidCRC,
    BinaryTooSmall,
};

pub const Table = struct {
    header: Header,
    entries: [128]?Entry = [1]?Entry{null} ** 128,

    pub fn readFromBinary(bin: []u8) !Table {
        var table: Table = undefined;
        table.header = Header.readFromBinary(bin[0..512]);
        if (!table.header.valid()) {
            std.log.err("Rejected header: {any}", .{table.header.crc32});
            return error.InvalidCRC;
        }
        for (0..128) |i| {
            var entry = Entry.readFromBinary(bin[i * 128 + 512 .. (i + 1) * 128 + 512]);
            const entry_type = entry.type_guid.gpt_partition_type();
            if (entry_type == .unused or entry_type == .unknown) continue;
            table.entries[i] = entry;
        }
        return table;
    }
};
