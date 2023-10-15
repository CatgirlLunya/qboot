const std = @import("std");
const elf = std.elf;

pub const ElfFile = struct {
    header: elf.Header,

    pub fn parse(file_input: anytype) !ElfFile {
        var file: ElfFile = undefined;
        file.header = try elf.Header.read(file_input);
        var iterator = file.header.program_header_iterator(file_input);
        // Keep track of how much memory is needed to allocate
        var bottom: u64 = 0xFFFFFFFFFFFFFFFF;
        var top: u64 = 0;
        // 32 bit non-paging code, update later
        // Also do things with top and bottom for dynamic allocation
        while (try iterator.next()) |i| {
            if (i.p_type != elf.PT_LOAD) continue; // Dont care about unloadable segments, can't dynamically link anyways
            if (i.p_paddr < 0x200000) return error.SegmentTooLow;
            if (i.p_paddr < bottom) bottom = i.p_paddr;
            if (i.p_paddr + i.p_memsz > top) top = i.p_paddr + i.p_memsz;
        }
        return file;
    }

    pub fn loadIntoMemory(self: *ElfFile, file_input: anytype) !void {
        var iterator = self.header.program_header_iterator(file_input);
        while (try iterator.next()) |i| {
            if (i.p_type != elf.PT_LOAD) continue;
            var ptr = @as([*]u8, @ptrFromInt(@as(usize, @intCast(i.p_paddr))));
            try file_input.seekableStream().seekTo(i.p_offset);
            _ = try file_input.reader().read(ptr[0..@intCast(i.p_filesz)]);
        }
    }

    pub fn entryPoint(self: *ElfFile) u64 {
        return self.header.entry;
    }
};
