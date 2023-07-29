#pragma once

#include <stdint.h>
#include <stdbool.h>

#include "cstd/memory.h"
#include "cstd/math.h"
#include "terminal/debug.h"

// Info on RSDP from https://wiki.osdev.org/RSDP

struct RSDP {
    char signature[8];
    uint8_t checksum;
    char oem_id[6];
    uint8_t revision;
    uint32_t rsdt_address;
}__attribute__((packed));

struct RSDPExtended {
    struct RSDP rsdp;

    uint32_t length;
    uint64_t xsdt_address;
    uint8_t extended_checksum;
    uint8_t reserved[3];
}__attribute__((packed));

// Returns 0 if not found, 1 if RSDP valid but not RSDPExtended, 2 if both valid
int RSDTLocateRSDP(struct RSDPExtended* rsdp);
