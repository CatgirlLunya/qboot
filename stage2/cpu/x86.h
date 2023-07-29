#pragma once

#include <stdint.h>

void outb(uint16_t port, uint8_t value);
uint8_t inb(uint16_t port);

// Read/Write Model Specific Registers, list in Volume 4 of Intel Software Developer's Manual
uint64_t rdmsr(uint32_t msr);
void wrmsr(uint32_t msr, uint64_t value);
