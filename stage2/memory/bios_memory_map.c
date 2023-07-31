#include "bios_memory_map.h"
#include "cpu/real_mode.h"
#include "terminal/debug.h"

#define MAX_MEMMAP_ENTRIES 256

struct MemoryMapEntry MemoryMap[MAX_MEMMAP_ENTRIES];
size_t MemoryMapEntries = 0;

void PopulateMemoryMap(void) {
    struct RealModeRegisters registers = {0};
    for (size_t i = 0; i < MAX_MEMMAP_ENTRIES; i++) {
        MemoryMap[i].flags = 1; // Set this, because if ACPI 3.0 is enabled it sets it to 0 if the entry is unusable
        registers.eax = BIOS_GET_MEMMAP_PARAM;
        registers.ecx = sizeof(struct MemoryMapEntry);
        registers.edx = BIOS_GET_MEMMAP_MAGIC;
        registers.edi = (uint32_t)&MemoryMap[i];

        BIOSInterrupt(BIOS_GET_MEMMAP_INT, &registers, &registers);
        if (registers.eflags & FLAGS_CARRY_SET) { // BIOS sets carry when you access entry *after* final
            MemoryMapEntries = i;
            return;
        }

        if (registers.ecx == 24 && !(MemoryMap[i].flags & 1)) { // ACPI 3.0 extension
            continue;
        }

        if (registers.eax != BIOS_GET_MEMMAP_MAGIC) {
            DebugCritical("Wrong BIOS Memmap signature!");
        }

        if (registers.ebx == 0) { // BIOS may set ebx to 0 when you read the final entry
            MemoryMapEntries = ++i;
            return;
        }
    }
}
