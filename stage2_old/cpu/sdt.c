#include "sdt.h"
#include "rsdp.h"
#include "terminal/debug.h"
#include "terminal/terminal.h"

bool ValidateChecksum(void* ptr, size_t size) {
    uint8_t checksum = 0;
    for (size_t i = 0; i < size; i++) {
        checksum += ((uint8_t*)ptr)[i];
    }
    if (checksum != 0) return false;
    return true;
}

int RSDTRead(struct RSDP* rsdp, struct SDT* rsdt) {
    MemoryCopy((void*)rsdt, (const void*)rsdp->rsdt_address, sizeof(struct ACPITableHeader));
    // Validate table by checking signature and checksum
    if (MemoryCompare(rsdt->header.signature, "RSDT", 4) != 0) return 0;
    if (!ValidateChecksum((void*)rsdp->rsdt_address, rsdt->header.size)) return 0;

    // Other sdts come immediately after header, so make it point there in memory
    rsdt->RSDT.other_sdts = (uint32_t*)(rsdp->rsdt_address + sizeof(struct ACPITableHeader));
    rsdt->RSDT.count = (rsdt->header.size - sizeof(struct ACPITableHeader)) / 4;
    rsdt->type = kRSDT;

    return 1;
}

static char* SignatureForType[] = {
    "APIC",
    "RSDT",
    "XSDT",
};

#define READ_FROM_POINTER(ptr, type) *((type*)ptr); ptr += sizeof(type)

int SDTRead(struct SDT* rsdt, struct SDT* sdt) {
    if (rsdt->type != kRSDT) return 0;
    uint8_t* sdt_data_ptr = NULL;
    for (size_t i = 0; i < rsdt->RSDT.count; i++) {
        void* ptr = (void*)rsdt->RSDT.other_sdts[i];
        if (MemoryCompare(ptr, SignatureForType[sdt->type], 4) == 0) {
            sdt_data_ptr = ptr;
            break; 
        }
    }
    if (sdt_data_ptr == NULL) return 0;

    switch (sdt->type) {
        case kAPIC: {
            MemoryCopy(&sdt->header, sdt_data_ptr, sizeof(struct ACPITableHeader));
            if (!ValidateChecksum((void*)sdt_data_ptr, sdt->header.size)) return 0;
            uint8_t* end_ptr = sdt_data_ptr + sdt->header.size;
            sdt_data_ptr += sizeof(struct ACPITableHeader);
            sdt->APIC.apic_address = READ_FROM_POINTER(sdt_data_ptr, uint32_t);
            sdt->APIC.flags = READ_FROM_POINTER(sdt_data_ptr, uint32_t);
            // TODO: MADT
            // Need this because the loop always sets the next node but sdt->APIC.entries should be first to be set
            while (end_ptr - sdt_data_ptr > 0) {
                struct MADTEntry node;
                uint8_t* sdt_data_ptr_copy = sdt_data_ptr; // Not sure what to name this but used to verify size
                node.type = (enum MADTEntryType)READ_FROM_POINTER(sdt_data_ptr, uint8_t);
                node.size = READ_FROM_POINTER(sdt_data_ptr, uint8_t);
                bool insert = true;
                switch (node.type) {
                    case kProcessorLocalAPIC: {
                        node.ProcessorLocalAPIC.processor_id = READ_FROM_POINTER(sdt_data_ptr, uint8_t);
                        node.ProcessorLocalAPIC.apic_id = READ_FROM_POINTER(sdt_data_ptr, uint8_t);
                        node.ProcessorLocalAPIC.flags = READ_FROM_POINTER(sdt_data_ptr, uint32_t);
                        break;
                    }
                    case kIOAPIC: {
                        node.IOAPIC.ioapic_id = READ_FROM_POINTER(sdt_data_ptr, uint8_t);
                        sdt_data_ptr++; // Reserved byte
                        node.IOAPIC.ioapic_address = READ_FROM_POINTER(sdt_data_ptr, uint32_t);
                        node.IOAPIC.global_system_interrupt_base = READ_FROM_POINTER(sdt_data_ptr, uint32_t);
                        break;
                    }
                    case kIOAPICInterruptSourceOverride: {
                        node.IOAPICInterruptSourceOverride.bus_source = READ_FROM_POINTER(sdt_data_ptr, uint8_t);
                        node.IOAPICInterruptSourceOverride.irq_source = READ_FROM_POINTER(sdt_data_ptr, uint8_t);
                        node.IOAPICInterruptSourceOverride.flags = READ_FROM_POINTER(sdt_data_ptr, uint16_t);
                        node.IOAPICInterruptSourceOverride.global_system_interrupt = READ_FROM_POINTER(sdt_data_ptr, uint32_t);
                        break;
                    }
                    case kIOAPICNonMaskableInterruptSource: {
                        node.IOAPICNonMaskableInterruptSource.nmi_source = READ_FROM_POINTER(sdt_data_ptr, uint8_t);
                        sdt_data_ptr++; // Reserved byte
                        node.IOAPICNonMaskableInterruptSource.flags = READ_FROM_POINTER(sdt_data_ptr, uint16_t);
                        node.IOAPICNonMaskableInterruptSource.global_system_interrupt = READ_FROM_POINTER(sdt_data_ptr, uint32_t);
                        break;
                    }
                    case kLAPICNonMaskableInterrupts: {
                        node.LAPICNonMaskableInterrupts.processor_id = READ_FROM_POINTER(sdt_data_ptr, uint8_t);
                        node.LAPICNonMaskableInterrupts.flags = READ_FROM_POINTER(sdt_data_ptr, uint16_t);
                        node.LAPICNonMaskableInterrupts.LINT_number = READ_FROM_POINTER(sdt_data_ptr, uint8_t);
                        break;
                    }
                    case kLAPICAddressOverride: {
                        sdt_data_ptr += 2; // Reserved 2 bytes
                        node.LAPICAddressOverride.lapic_address = READ_FROM_POINTER(sdt_data_ptr, uint64_t);
                        break;
                    }
                    case kProcessorLocalx2APIC:{
                        sdt_data_ptr += 2; // Reserved 2 bytes
                        node.ProcessorLocalx2APIC.processor_local_x2apic_id = READ_FROM_POINTER(sdt_data_ptr, uint32_t);
                        node.ProcessorLocalx2APIC.flags = READ_FROM_POINTER(sdt_data_ptr, uint32_t);
                        node.ProcessorLocalx2APIC.acpi_id = READ_FROM_POINTER(sdt_data_ptr, uint32_t);
                        break;
                    }
                    default: {
                        sdt_data_ptr += node.size - 2;
                        insert = false;
                        break;
                    }
                }
                if (sdt_data_ptr_copy + node.size != sdt_data_ptr) {
                    return 0;
                }
                if (insert) {
                    
                }
            }
            break;
        }
        case kXSDT:
        case kRSDT: 
            return 0;
    }
    return 1;
}

#undef READ_FROM_POINTER
