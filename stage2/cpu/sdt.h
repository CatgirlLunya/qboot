#pragma once

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#include "cstd/memory.h"
#include "cpu/rsdp.h"

// This is the header for every table the APCI stores, except for the RSDP
struct ACPITableHeader {
    char signature[4];
    uint32_t size;
    uint8_t revision;
    uint8_t checksum;
    char oem_id[6];
    char oem_table_id[8];
    uint32_t oem_revision;
    uint32_t creator_id;
    uint32_t creator_revision;
}__attribute__((packed));

// All acronyms so I'm leaving them all capital 
enum SDTType {
    kAPIC,
    kRSDT,
    kXSDT,
};

// https://wiki.osdev.org/MADT
enum MADTEntryType {
    kProcessorLocalAPIC = 0,
    kIOAPIC,
    kIOAPICInterruptSourceOverride,
    kIOAPICNonMaskableInterruptSource,
    kLAPICNonMaskableInterrupts,
    kLAPICAddressOverride,
    kProcessorLocalx2APIC = 9,
};

// https://uefi.org/specs/ACPI/6.5/05_ACPI_Software_Programming_Model.html#multiple-apic-description-table-madt
struct MADTEntry {
    enum MADTEntryType type;
    uint8_t size;
    union {
        struct {
            uint8_t processor_id;
            uint8_t apic_id;
            uint32_t flags; // bit 0 = processor enabled, bit 1 = capable of being enabled
        } ProcessorLocalAPIC;
        struct {
            uint8_t ioapic_id;
            uint32_t ioapic_address;
            uint32_t global_system_interrupt_base; // the first interrupt number that this I/O APIC handles
        } IOAPIC;
        struct {
            uint8_t bus_source;
            uint8_t irq_source;
            uint32_t global_system_interrupt;
            uint16_t flags;
        } IOAPICInterruptSourceOverride;
        struct {
            uint8_t nmi_source;
            uint16_t flags;
            uint32_t global_system_interrupt;
        } IOAPICNonMaskableInterruptSource;
        struct {
            uint8_t processor_id;
            uint16_t flags;
            uint8_t LINT_number; // 0 or 1
        } LAPICNonMaskableInterrupts;
        struct {
            uint64_t lapic_address; // 64-bit physical address of Local APIC
        } LAPICAddressOverride;
        struct {
            uint32_t processor_local_x2apic_id;
            uint32_t flags; // Same as LAPIC flags(type kProcessorLocalAPIC)
            uint32_t acpi_id;
        } ProcessorLocalx2APIC;
    };
};

// Turns out using packed structs and discriminated unions doesn't work so I'm leaving this unpacked
// TODO: Unpack all structs(where possible)
// Windows ACPI Emulated Devices Table exists on windows qemu even on wsl
struct SDT {
    struct ACPITableHeader header;
    union {
        struct {
            uint32_t apic_address;
            uint32_t flags; // 1 = 8259 PICs installed
            // TODO: ADD MADT ENTRIES 
        } APIC;
        struct {
            uint32_t* other_sdts;
            uint32_t count;
        } RSDT;
        struct {
            uint64_t* other_sdts;
        } XSDT;
    };
    enum SDTType type;
};

// Returns 0 if not found, 1 if found
int RSDTRead(struct RSDP* rsdp, struct SDT* rsdt);

// Returns 0 if not found, 1 if found
// Pass in SDT with type set to what type you want
int SDTRead(struct SDT* rsdt, struct SDT* sdt);
