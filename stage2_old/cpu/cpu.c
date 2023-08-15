#include "cpu.h"

bool CPUID(unsigned int leaf, struct Registers* registers) {
    return (bool)__get_cpuid(leaf, &registers->eax, &registers->ebx, &registers->ecx, &registers->edx);
}

// "When the CPUID instruction is executed with a source operand of 1 in the EAX register, bit 9 of the CPUID feature flags returned in the EDX register indicates the presence (set) or absence (clear) of a local APIC." - Intel Software Developer's Manual, Volume 3, 11.4.2 
bool CPUAPICSupported(void) {
    struct Registers registers;
    if (!CPUID(1, &registers)) return false;
    return registers.edx & (1 << 9); // also equivalent to 0b100000000
}
