#include "bios_memory_map.h"
#include "cpu/real_mode.h"
#include "terminal/debug.h"

#define MAX_MEMMAP_ENTRIES 256

struct MemoryMapEntry MemoryMap[MAX_MEMMAP_ENTRIES];
size_t MemoryMapEntries = 0;

void MemoryMapPopulate(void) {
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
            break;
        }

        if (registers.ecx == 24 && !(MemoryMap[i].flags & 1)) { // ACPI 3.0 extension
            continue;
        }

        if (MemoryMap[i].type > 5 || MemoryMap[i].type == 0) MemoryMap[i].type = 5; // Set all types I don't want to deal with to bad memory

        if (registers.eax != BIOS_GET_MEMMAP_MAGIC) {
            DebugCritical("Wrong BIOS Memmap signature!");
        }

        if (registers.ebx == 0) { // BIOS may set ebx to 0 when you read the final entry
            MemoryMapEntries = ++i;
            break;
        }
    }
}

void CleanMemoryMapInvalidEntries(void) {
    for (size_t i = 0; i < MemoryMapEntries; i++) {
        if (MemoryMap[i].length != 0) continue;

        for (size_t j = i; j < MemoryMapEntries - 1; j++) {
            MemoryMap[j] = MemoryMap[j+1];
        }
        i--;
        MemoryMapEntries--;
    }
}

// Algorithm for fixing overlapped regions:
/* for checker in map {
        if (checker is usable) skip
        for collider in map {
            if (checker == collider) skip
            if !(checker.base < collider.base and checker.base + checker.length > j.base) skip
            // collider is confirmed to be partially or fully in checker
            if (collider priority >= checker priority) skip
            // if collider is fully inside checker, delete it
            // else, move up collider and shrink length so checker can take over its full space
        }
    }
*/

// Page tables should never be overwritten
static int MemoryTypePriorityLevel[kMaxMemoryTypes] = {
    -1, 0, 2, 1, 2, 3, 4, 4
};

void MemoryMapFix(void) {
    // Change unrecognized types to be "bad"
    for (size_t i = 0; i < MemoryMapEntries; i++) {
        if (MemoryMap[i].type >= kMaxMemoryTypes || MemoryMap[i].type < kUsableRAM) MemoryMap[i].type = 5; 
    }

    // Combine adjacent segments of the same type, done before colliding different segments to make it cleaner
    for (size_t i = 0; i < MemoryMapEntries; i++) {
        struct MemoryMapEntry* checker = &MemoryMap[i];
        if (checker->length == 0) continue;
        for (size_t j = 0; j < MemoryMapEntries; j++) {
            struct MemoryMapEntry* collider = &MemoryMap[j];
            if (i == j) continue;
            if (collider->length == 0) continue;
            if (checker->type != collider->type) continue;
            if (collider->base < checker->base || collider->base > checker->base + checker->length) continue; // Not colliding
            // Beginning of new segment should be the lowest base, length should be enough to encompass both
            uint64_t begin = MIN(collider->base, checker->base);
            uint64_t end = MAX(collider->base + collider->length, checker->base + checker->length);
            uint64_t len = end - begin;
            collider->base = begin;
            collider->length = len;
            checker->length = 0;
        }
    }

    CleanMemoryMapInvalidEntries();

    // Fixing regions of unusable memory and usable memory that overlap because apparently this occurs sometimes
    for (size_t i = 0; i < MemoryMapEntries; i++) {
        struct MemoryMapEntry* checker = &MemoryMap[i];
        if (checker->length == 0) continue;
        for (size_t j = 0; j < MemoryMapEntries; j++) {
            struct MemoryMapEntry* collider = &MemoryMap[j];
            if (i == j) continue;
            if (collider->length == 0) continue;
            if (checker->base > collider->base || checker->base + checker->length <= collider->base) continue; // collider is not in checker
            bool fully_inside = collider->base + collider->length <= checker->base + checker->length;
            if (MemoryTypePriorityLevel[collider->type] > MemoryTypePriorityLevel[checker->type]) {
                if (fully_inside) {
                    struct MemoryMapEntry entry = {
                        .base = collider->base + collider->length,
                        .length = checker->length + checker->base - (collider->base + collider->length), // checker.end - collider.end
                        .type = checker->type,
                        .flags = checker->flags,
                    };
                    MemoryMapInsert(entry);
                    checker->length = collider->base - checker->base;
                } else {
                    checker->length = collider->base - checker->base;
                }
            } else if (MemoryTypePriorityLevel[collider->type] == MemoryTypePriorityLevel[checker->type]) {
                continue; // This shouldn't ever happen because colliding segments of the same type already handled
            } else {
                if (fully_inside) {
                    // Collider is fully inside checker
                    collider->length = 0; // Mark for removal
                } else {
                    // Subtract how much the collider base has to move
                    collider->length -= ((checker->base + checker->length) - collider->base);
                    collider->base = checker->base + checker->length;
                }
            }
        }
    }

    CleanMemoryMapInvalidEntries();
}

size_t MemoryMapInsert(struct MemoryMapEntry entry) {
    if (MemoryMapEntries > MAX_MEMMAP_ENTRIES) {
        DebugError("Too many memmap entries!");
        return (size_t)-1;
    }
    MemoryMap[MemoryMapEntries] = entry;
    MemoryMapEntries++;
    return MemoryMapEntries - 1;
}

