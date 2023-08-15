#include "rsdp.h"

// RSDP can be located in the first KB of EBDA(a pointer to EBDA is at 0x40E) or somewhere in between 0xE0000 to 0xFFFFF
int RSDPLocate(struct RSDPExtended* rsdp) {
    uint16_t ebda_pointer = *(uint16_t*)0x40E;
    uint32_t ebda = (uint32_t)ebda_pointer << 4;
    size_t search_limit = MIN(1024, 0xA0000 - ebda);
    for (size_t i = 0; i < search_limit; i += 16) {
        if (MemoryCompare((const void*)(ebda+i), "RSD PTR ", 8) == 0) {
            MemoryCopy(&rsdp->rsdp, (void*)(ebda+i), sizeof(struct RSDP));
            if (rsdp->rsdp.revision == 2) {
                MemoryCopy(&rsdp, (void*)(ebda+i), sizeof(struct RSDPExtended));
                return 2;
            }
            return 1;
        }
    }

    // Now search between 0xE0000 - 0xFFFFF
    for (size_t address = 0xE0000; address < 0xFFFFF; address += 16) {
        if (MemoryCompare((const void*)address, "RSD PTR ", 8) == 0) {
            MemoryCopy(&rsdp->rsdp, (void*)address, sizeof(struct RSDP));
            uint8_t byte_sum = 0;
            for (size_t j = 0; j < sizeof(struct RSDP); j++)
                byte_sum += ((uint8_t*)address)[j];
            if (byte_sum != 0) continue; // Checksum invalid, so this table is invalid too
            
            if (rsdp->rsdp.revision == 2) {
                MemoryCopy(&rsdp, (void*)address, sizeof(struct RSDPExtended));
                return 2;
            }
            return 1;
        }
    }

    return 0;
}
