#include "x86.h"

void outb(uint16_t port, uint8_t value) {
    // value has "a" because outb uses al for the value
    // port has "Nd" because outb uses dx for the port and is used in out/in instructions
    // "memory" is used to tell compiler not to move this
    // https://gcc.gnu.org/onlinedocs/gcc/Machine-Constraints.html - x86 family
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port) : "memory"); 
}

uint8_t inb(uint16_t port)  {
    uint8_t ret;
    // Ret has "=a" to signify that it is written to and it comes from ax
    // "Nd" and "memory" same as outb
    __asm__ volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port) : "memory");
    return ret;
}

uint64_t rdmsr(uint32_t msr) {
    // Splits the return into the lower and higher bits b/c smaller than using a union
    uint64_t value;
    uint32_t* split_value = (uint32_t*)&value;

    // rdmsr takes in the lower in eax and higher in edx, and the msr index in ecx
    __asm__ volatile ("rdmsr" : "=a"(split_value[0]), "=d"(split_value[1]) : "c"(msr));

    return value;
}

void wrmsr(uint32_t msr, uint64_t value) {
    uint32_t* split_value = (uint32_t*)&value;
    __asm__ volatile ("wrmsr" : : "a"(split_value[0]), "d"(split_value[1]), "c"(msr));
}
