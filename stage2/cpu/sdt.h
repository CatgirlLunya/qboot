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

struct RSDT {
    struct ACPITableHeader header;
    void** other_sdts; // count = (size - 36) / 4, b/c size includes these
    size_t sdt_count; // Not included in the binary data but added on for convenience
}__attribute__((packed));

// All acronyms so I'm leaving them all capital 
enum SDTType {
    kAPIC,
    kRSDT,
    kXSDT,
};

// Turns out using packed structs and discriminated unions doesn't work so I'm leaving this unpacked
// TODO: Unpack all structs(where possible)
struct SDT {
    struct ACPITableHeader header;
    union {
        struct {
            uint32_t apic_address;
            uint32_t flags;
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
int SDTRead(struct RSDT* rsdt, struct SDT* sdt);
