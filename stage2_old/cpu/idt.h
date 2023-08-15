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

// Format can be found at https://wiki.osdev.org/IDT
// Flags: PDD0GGGG
// - P is the Present Bit, must be set to 1 for all valid entries
// - D is the Cpu Priviledge Level needed to use INT to use this, 0-3
// - G is the Gate Type
union IDTEntryFlags {
    // Lets you cleanly access the flags
    uint8_t flags;
    struct __attribute__((packed)){
        uint8_t gate_type : 4;
        uint8_t reserved : 1;
        uint8_t cpu_priviledge_level : 2;
        uint8_t present : 1;
    };
}__attribute__((packed));

struct IDTEntry {
    uint16_t isr_low;
    uint16_t kernel_cs;
    uint8_t reserved;
    union IDTEntryFlags flags;
    uint16_t isr_high;
}__attribute__((packed));

struct IDTEntry IDTMakeEntry(void(*isr)(void), union IDTEntryFlags flags);

struct IDTDescriptor {
    uint16_t size;  // 1 less than the size of the IDT in bytes
    struct IDTEntry* idt;
} __attribute__((packed));

void IDTInsertEntry(uint8_t index, struct IDTEntry entry);
void IDTInit(void);
void IDTEnable(void);
