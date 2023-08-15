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

bool CPUID(unsigned int leaf, struct Registers* registers);
bool CPUAPICSupported(void);
