#include "idt.h"

// Apparently aligning gives performance? https://wiki.osdev.org/Interrupts_Tutorial
__attribute__((aligned(0x10)))
static struct IDTEntry kIDTTable[256];

static struct IDTDescriptor kIDTDescriptor = {
    .idt = kIDTTable,
    .size = sizeof(struct IDTEntry) * 256 - 1,
};

void IDTInsertEntry(uint8_t index, struct IDTEntry entry) {
    kIDTTable[index] = entry;
}

struct IDTEntry IDTMakeEntry(void(*isr)(void), union IDTEntryFlags flags) {
    struct IDTEntry entry = {
        .isr_low = (uint32_t)isr & 0xFFFF,
        .kernel_cs = 0x08,
        .reserved = 0,
        .flags = flags,
        .isr_high = (uint16_t)((uint32_t)isr >> 16),
    };

    return entry;
}

struct InterruptRegisters {
    uint32_t edi, esi, ebp, esp, ebx, edx, ecx, eax; // Order pusha pushes registers in
    uint32_t interrupt_number, error_code; // Pushed in isr.asm
    uint32_t eip, cs, eflags; // Pushed by CPU https://wiki.osdev.org/Interrupt_Service_Routines
};

char* exception_messages[32] = {
    "Division By Zero",
    "Debug",
    "Non Maskable Interrupt",
    "Breakpoint",
    "Into Detected Overflow",
    "Out of Bounds",
    "Invalid Opcode",
    "No Coprocessor",
    "Double Fault",
    "Coprocessor Segment Overrun",
    "Bad TSS",
    "Segment Not Present",
    "Stack Fault",
    "General Protection Fault",
    "Page Fault",
    "Unknown Interrupt",
    "Coprocessor Fault",
    "Alignment Check",
    "Machine Check",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved"
};


void CISRHandler(struct InterruptRegisters registers) {
    TerminalWriteString("Interrupt Message: ");
    TerminalWriteString(exception_messages[registers.interrupt_number]);
    for (;;);
}

#define EXCEPTION(num) extern void exception##num(void)

EXCEPTION(0); EXCEPTION(1); EXCEPTION(2); EXCEPTION(3);
EXCEPTION(4); EXCEPTION(5); EXCEPTION(6); EXCEPTION(7);
EXCEPTION(8); EXCEPTION(9); EXCEPTION(10); EXCEPTION(11);
EXCEPTION(12); EXCEPTION(13); EXCEPTION(14); EXCEPTION(15);
EXCEPTION(16); EXCEPTION(17); EXCEPTION(18); EXCEPTION(19);
EXCEPTION(20); EXCEPTION(21); EXCEPTION(22); EXCEPTION(23);
EXCEPTION(24); EXCEPTION(25); EXCEPTION(26); EXCEPTION(27);
EXCEPTION(28); EXCEPTION(29); EXCEPTION(30); EXCEPTION(31);

typedef void(*isr)(void);

isr isr_list[32] = {
    exception0, exception1, exception2, exception3,
    exception4, exception5, exception6, exception7,
    exception8, exception9, exception10, exception11,
    exception12, exception13, exception14, exception15,
    exception16, exception17, exception18, exception19,
    exception20, exception21, exception22, exception23,
    exception24, exception25, exception26, exception27,
    exception28, exception29, exception30, exception31,
};

void IDTInit(void) {
    for (uint8_t i = 0; i < 32; i++) {
        struct IDTEntry entry = IDTMakeEntry(isr_list[i], (union IDTEntryFlags){
            .reserved = 0,
            .cpu_priviledge_level = 0,
            .gate_type = kInterruptGate32,
            .present = 1,
        });
        IDTInsertEntry(i, entry);
    }
    
    __asm__ volatile ("lidt %0" :: "m"(kIDTDescriptor));
}

void IDTEnable(void) {
    __asm__ volatile ("sti");
}
