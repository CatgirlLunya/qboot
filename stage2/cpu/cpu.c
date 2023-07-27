#include "cpu.h"

bool CPUID(unsigned int leaf, struct Registers* registers) {
    return (bool)__get_cpuid(leaf, &registers->eax, &registers->ebx, &registers->ecx, &registers->edx);
}
