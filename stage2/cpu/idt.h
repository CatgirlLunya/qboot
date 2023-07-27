#pragma once

#include <stdint.h>
#include "terminal/terminal.h"

// Will use the same code segment, 0x8, as defined in the bootsector's GDT
// https://wiki.osdev.org/Segment_Selector for format
// Binary constants are a GCC extension apparently so can't use those
#define IDT_SEGMENT_SELECTOR 0x40 // 0b0000000001000000

enum GateType {
    kTaskGate = 0x5,
    kInterruptGate16 = 0x6,
    kTrapGate16 = 0x7,
    kInterruptGate32 = 0xE,
    kTrapGate32 = 0xF,
};

struct IDTEntry {
    uint32_t offset;
    enum GateType gate_type;
};

struct IDTDescriptor {
    uint64_t* idt;
    uint16_t size;  // 1 less than the size of the IDT in bytes
} __attribute__((packed));

void IDTInsertEntry(uint8_t index, struct IDTEntry entry);
void IDTInit(void);
