#pragma once

#include <stdint.h>

inline void outb(uint16_t port, uint8_t value) {
    // value has "a" because outb uses al for the value
    // port has "Nd" because outb uses dx for the port and is used in out/in instructions
    // "memory" is used to tell compiler not to move this
    // https://gcc.gnu.org/onlinedocs/gcc/Machine-Constraints.html - x86 family
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port) : "memory"); 
}

inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    // Ret has "=a" to signify that it is written to and it comes from ax
    // "Nd" and "memory" same as outb
    __asm__ volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port) : "memory");
    return ret;
}
