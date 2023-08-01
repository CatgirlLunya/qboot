#pragma once

#include <stdint.h>
#include <stddef.h>

#include "cpu/real_mode.h"
#include "cstd/math.h"

#define BIOS_GET_MEMMAP_INT   0x15
#define BIOS_GET_MEMMAP_PARAM 0xE820
#define BIOS_GET_MEMMAP_MAGIC 0x534D4150

// Only 1 is valid for reclaiming b/c still using ACPI tables
// Also have page table types to tell kernel what it can overwrite when
enum MemoryMapEntryType {
    kUsableRAM = 1,
    kReserved,
    kACPIReclaimable,
    kACPINVSMemory,
    kAreaBadMemory,
    k32bitPageTable,
    k32bitPageFrame,
    k64bitPageTable,
    k64bitPageFrame,
    kMaxMemoryTypes,
};

struct MemoryMapEntry {
    uint64_t base;
    uint64_t length;
    uint32_t type;
    uint32_t flags; // ACPI 3.0 Extended Attributes bitfield
};

extern struct MemoryMapEntry MemoryMap[];
extern size_t MemoryMapEntries;

void MemoryMapPopulate(void);
void MemoryMapFix(void);
size_t MemoryMapInsert(struct MemoryMapEntry entry);
