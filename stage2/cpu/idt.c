#include "idt.h"

static uint64_t kIDTTable[255];

static struct IDTDescriptor kIDTDescriptor = {
    .idt = kIDTTable,
    .size = sizeof(uint64_t) * 255 - 1,
};

// Format can be found at https://wiki.osdev.org/IDT
// Could use a macro, but this is cleaner and could be optimized anyways
uint64_t GateDescriptorFromIDTEntry(struct IDTEntry entry) {
    uint64_t value = (((uint64_t)entry.offset) >> 16) << 48;
    value += (((uint64_t)1 << 47) + ((uint64_t)entry.gate_type << 40));
    value += IDT_SEGMENT_SELECTOR << 16;
    value += entry.offset & 0xFFFF;
    return value;
}

void IDTInsertEntry(uint8_t index, struct IDTEntry entry) {
    kIDTTable[index] = GateDescriptorFromIDTEntry(entry);
}

struct InterruptRegisters {
    uint32_t edi, esi, ebp, esp, ebx, edx, ecx, eax; // Order pusha pushes registers in
    uint32_t interrupt_number, error_code; // Pushed in isr.asm
    uint32_t eip, cs, eflags; // Pushed by CPU https://wiki.osdev.org/Interrupt_Service_Routines
};

void CISRHandler(struct InterruptRegisters registers) {
    TerminalWriteString("Hello, world!");
    TerminalWriteChar('0' + registers.interrupt_number);
}

void IDTInit(void) {
    struct IDTEntry entry = {
        .gate_type = kTrapGate32,
        .offset = (uint32_t)CISRHandler,
    };

    for (uint8_t i = 0; i < 32; i++) {
        IDTInsertEntry(i, entry);
    }
    
    __asm__ volatile ("lidt %0" :: "m"(kIDTDescriptor));
}
