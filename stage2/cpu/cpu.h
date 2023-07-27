#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <cpuid.h>

struct Registers {
    unsigned int eax;
    unsigned int ebx;
    unsigned int ecx;
    unsigned int edx;
};

void GetRegisters(struct Registers* registers);
bool CPUID(unsigned int leaf, struct Registers* registers);
