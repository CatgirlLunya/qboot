#pragma once 

#include <stdbool.h>
#include <stdint.h>

#include "cpu/x86.h"
#include "cpu/cpu.h"
#include "cpu/sdt.h"

#define APIC_STATUS_MSR                     0x1B       // Taken from Intel Software Developer's Manual, Volume 4, 2.1
#define APIC_SPURIOUS_INTERRUPT_REGISTER    0xF0       // https://wiki.osdev.org/APIC#Local_APIC_and_IO-APIC
#define APIC_SPURIOUS_INTERRUPT_ENABLE      (1 << 9)   // Ditto

bool LAPICInit(void);

// Volume 3, 11.4.4
union LAPICStatus {
    uint64_t value;
    struct {
        uint8_t reserved3 : 8;
        bool bootstrap_processor : 1;
        uint8_t reserved2 : 2;
        bool enabled : 1;
        uint32_t base : 23; // Left shift by 12 to get real base address
        uint32_t reserved : 29;
    }__attribute__((packed));
};


union LAPICStatus LAPICGetStatus(void);
void LAPICSetStatus(union LAPICStatus status);
void LAPICEnable(struct SDT* madt);
void APICWriteRegister(struct SDT* madt, uint16_t reg, uint32_t value);
uint32_t APICReadRegister(struct SDT* madt, uint16_t reg);
