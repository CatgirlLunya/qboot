const std = @import("std");
const gpt = @import("gpt.zig");

pub const GUID = struct {
    data_1: u32,
    data_2: u16,
    data_3: u16,
    data_4: u64,

    pub fn readFromBinary(bin: []u8) GUID {
        var guid: GUID = undefined;
        guid.data_1 = std.mem.readIntLittle(u32, bin[0..4]);
        guid.data_2 = std.mem.readIntLittle(u16, bin[4..6]);
        guid.data_3 = std.mem.readIntBig(u16, bin[6..8]);
        guid.data_4 = std.mem.readIntBig(u64, bin[8..16]);
        return guid;
    }

    pub fn equals(self: *const GUID, other: GUID) bool {
        return self.data_1 == other.data_1 and self.data_2 == other.data_2 and self.data_3 == other.data_3 and self.data_4 == other.data_4;
    }

    pub fn gpt_partition_type(self: *const GUID) gpt.GptPartitionType {
        if (self.equals(GUID{ .data_1 = 0, .data_2 = 0, .data_3 = 0, .data_4 = 0 })) return .unused;
        if (self.equals(GUID{ .data_1 = 0xC12A7328, .data_2 = 0xF81F, .data_3 = 0xD211, .data_4 = 0xBA4B00A0C93EC93B })) return .efi_system;
        if (self.equals(GUID{ .data_1 = 0xBC13C2FF, .data_2 = 0x59E6, .data_3 = 0x6242, .data_4 = 0xA352B275FD6F7172 })) return .linux_boot_partition;
        if (self.equals(GUID{ .data_1 = 0x21686148, .data_2 = 0x6449, .data_3 = 0x6F6E, .data_4 = 0x744E656564454649 })) return .bios_boot;
        return .unknown;
    }
};
