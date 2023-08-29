pub const builtin = @import("builtin");

pub const MemoryType = enum(u32) {
    // These entries are ordered in the priority that their labels be preserved
    /// Always usable memory
    usable,
    /// Memory that the bootloader and its data are in
    bootloader,
    /// Memory the OS can reclaim after parsing the ACPI tables
    acpi_reclaimable,
    /// Never going to be usable
    unusable,
    /// Where the kernel is located
    kernel,
};

// May need to be laid out properly in memory for BIOS to work, so is made extern
pub const MemoryMapEntry = extern struct {
    base: u64,
    length: u64,
    memory_type: MemoryType,
};

pub const MaxMemoryMapEntries = switch (builtin.os.tag) {
    .freestanding => 256,
    .uefi => 1024,
    else => @compileError("Unimplemented"),
};

fn memoryEntryLessThan(_: @TypeOf({}), lhs: MemoryMapEntry, rhs: MemoryMapEntry) bool {
    return lhs.base < rhs.base;
}

pub const MemoryMap = struct {
    entries: [MaxMemoryMapEntries]MemoryMapEntry,
    count: usize,

    /// Removes entries with length 0
    pub fn removeEmpty(self: *MemoryMap) void {
        for (0..self.count) |e| {
            if (self.entries[e].length != 0) {
                continue;
            }
            for (e..self.count - 1) |i| {
                self.entries[i] = self.entries[i + 1];
            }
            self.count -= 1;
        }
    }

    pub fn sort(self: *MemoryMap) void {
        @import("std").sort.insertion(MemoryMapEntry, self.entries[0..self.count], {}, memoryEntryLessThan);
    }

    /// Combines memory map entries that touch or overlap of the same type
    pub fn minify(self: *MemoryMap) void {
        self.removeEmpty();
        var counter: u32 = 0;
        // Because the memory map is not necessarily in order, we do two loops
        // One that goes through every entry and holds it, and one that goes
        // through every entry and checks for collisions
        while (counter < self.count) : (counter += 1) {
            if (counter > MaxMemoryMapEntries) @panic("Memory map minify failed!");
            const outer = &self.entries[counter];
            if (outer.length == 0) continue;
            var inner_counter: u32 = 0;
            while (inner_counter < self.count) : (inner_counter += 1) {
                if (inner_counter > MaxMemoryMapEntries) @panic("Memory map minify failed!");
                if (inner_counter == counter) continue;
                const inner = &self.entries[inner_counter];
                if (inner.length == 0) continue;
                // If they don't touch, continue
                if (outer.base > inner.base or inner.base > outer.base + outer.length) continue;
                if (@intFromEnum(outer.memory_type) < @intFromEnum(inner.memory_type)) {
                    if (outer.base + outer.length > inner.base + inner.length) {
                        self.entries[self.count] = .{
                            .base = inner.base + inner.length,
                            .length = (outer.base + outer.length) - (inner.base + inner.length),
                            .memory_type = outer.memory_type,
                        };
                        self.count += 1;
                    }
                    outer.length = inner.base - outer.base;
                } else if (@intFromEnum(outer.memory_type) == @intFromEnum(inner.memory_type)) {
                    const newLength = @max(inner.base + inner.length - outer.base, outer.length);
                    outer.length = newLength;
                    inner.length = 0;
                    self.removeEmpty();
                    inner_counter -= 1;
                }
            }
        }
        self.removeEmpty();
        self.sort();
    }
};

/// What should be on every platform for memory map access; a pointer to a map and an init function that populates it
pub const MemoryInfo = struct {
    map: *MemoryMap,
    init: *const fn () anyerror!void,
};
