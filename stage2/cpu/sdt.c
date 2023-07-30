#include "sdt.h"
#include "rsdp.h"
#include "terminal/debug.h"
#include "terminal/terminal.h"

int RSDTRead(struct RSDP* rsdp, struct SDT* rsdt) {
    MemoryCopy((void*)rsdt, (const void*)rsdp->rsdt_address, sizeof(struct ACPITableHeader));
    // Validate table by checking signature and checksum
    if (MemoryCompare(rsdt->header.signature, "RSDT", 4) != 0) return 0;
    
    uint8_t checksum = 0;
    for (size_t i = 0; i < rsdt->header.size; i++) {
        checksum += ((uint8_t*)rsdp->rsdt_address)[i];
    }
    if (checksum != 0) return 0;

    // Other sdts come immediately after header, so make it point there in memory
    rsdt->RSDT.other_sdts = (uint32_t*)(rsdp->rsdt_address + sizeof(struct ACPITableHeader));
    rsdt->RSDT.count = (rsdt->header.size - sizeof(struct ACPITableHeader)) / 4;

    return 1;
}
