const memory = @import("api").memory;
const uefi = @import("std").os.uefi;

pub var memoryMap: memory.MemoryMap = undefined;
pub var mapKey: usize = undefined; // Needed to exit boot services

fn convertType(memory_type: u32) memory.MemoryType {
    return switch (memory_type) {
        0 => .unusable,
        1...4 => .bootloader,
        5...6 => .unusable,
        7 => .usable,
        8 => .unusable,
        9 => .acpi_reclaimable,
        10...13 => .unusable,
        14 => .usable,
        else => .unusable,
    };
}

pub fn loadMemoryMap() !void {
    const bs = uefi.system_table.boot_services.?;
    var buffer: [*]u8 = undefined;
    var size: usize = 0;
    var descriptor_size: usize = undefined;
    var descriptor_version: u32 = undefined;
    while (uefi.Status.BufferTooSmall == bs.getMemoryMap(&size, @ptrCast(@alignCast(buffer)), &mapKey, &descriptor_size, &descriptor_version)) {
        try bs.allocatePool(uefi.tables.MemoryType.BootServicesData, size, @ptrCast(&buffer)).err();
    }
    const entries = size / descriptor_size;
    if (entries > memory.MaxMemoryMapEntries) @panic("Too many memory map entries!");
    var ptr = buffer;
    for (0..entries) |e| {
        ptr = buffer + descriptor_size * e;
        const entry = @as(*uefi.tables.MemoryDescriptor, @ptrCast(@alignCast(ptr))).*;
        memoryMap.entries[e] = .{
            .base = entry.physical_start,
            .length = entry.number_of_pages * @import("std").mem.page_size,
            .memory_type = convertType(@intFromEnum(entry.type)),
        };
    }
    memoryMap.count = entries;
    try bs.freePool(@ptrCast(@alignCast(buffer))).err();
}

pub fn init() !void {
    try loadMemoryMap();
    try memoryMap.minify();
}
