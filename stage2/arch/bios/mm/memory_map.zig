const memory = @import("../../../api/api.zig").memory;
const real_mode = @import("../asm/real_mode.zig");
const frame = @import("../asm/frame.zig");

pub var memoryMap: memory.MemoryMap = undefined;

fn convertType(memory_type: u32) memory.MemoryType {
    return switch (memory_type) {
        1 => .usable,
        2 => .unusable,
        3 => .acpi_reclaimable,
        else => .unusable,
    };
}

const BiosMemmapEntry = extern struct {
    entry: memory.MemoryMapEntry,
    flags: u32,
};

// For whatever reason, this does not work if its not a global variable
var buffer: BiosMemmapEntry = undefined;

const MemoryMapErrors = error{
    BiosImplementationInvalid,
    OutOfMemoryMapSlots,
};

pub fn getMemoryMapFromBIOS() !void {
    const magic = 0x534D4150;
    const carry_flag = (1 << 0);
    var entry: u32 = 0;
    var registers: frame.Frame = .{
        .ebx = 0,
        .edi = @intFromPtr(&buffer),
    };
    while (entry < memory.MaxMemoryMapEntries) : (entry += 1) {
        registers.eax = 0xE820;
        registers.edx = magic;
        registers.ecx = 24;
        buffer.flags = 1; // If ACPI 3.0 is enabled it sets this to 0 if the entry should be ignored
        real_mode.biosInterrupt(0x15, &registers, &registers);
        // Interrupt sets carry bit after final one has been processed
        if (registers.eflags & carry_flag == 1) {
            memoryMap.count = entry;
            return;
        }
        // ACPI will set this to 0 if the entry should be ignored
        if (buffer.flags & 1 == 0) {
            entry -= 1;
            continue;
        }
        if (registers.eax != magic) {
            @import("std").log.err("Error: eax = {x}", .{registers.eax});
            return error.BiosImplementationInvalid;
        }
        memoryMap.entries[entry] = .{
            .base = buffer.entry.base,
            .length = buffer.entry.length,
            .memory_type = convertType(@intFromEnum(buffer.entry.memory_type)),
        };
        // BIOS may set ebx to 0 on the final entry
        if (registers.ebx == 0) {
            memoryMap.count = entry + 1;
            return;
        }
    }

    return error.OutOfMemoryMapSlots;
}

pub fn init() !void {
    try getMemoryMapFromBIOS();
}
