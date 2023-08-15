#pragma once

#include <stdint.h>

// From https://github.com/limine-bootloader/limine/blob/v5.x-branch/common/lib/real.h
struct RealModeRegisters {
    uint16_t gs;
    uint16_t fs;
    uint16_t es;
    uint16_t ds;
    uint32_t eflags;
    uint32_t ebp;
    uint32_t edi;
    uint32_t esi;
    uint32_t edx;
    uint32_t ecx;
    uint32_t ebx;
    uint32_t eax;
} __attribute__((packed));

#define FLAGS_CARRY_SET (1 << 0)

extern void BIOSInterrupt(uint8_t interrupt, struct RealModeRegisters* out, struct RealModeRegisters* in);