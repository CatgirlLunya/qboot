#include "terminal/debug.h"
#include "terminal/terminal.h"
#include "cpu/cpu.h"
#include "cpu/idt.h"
#include "cpu/lapic.h"
#include "cpu/pic.h"
#include "cpu/sdt.h"
#include "cpu/rsdp.h"
#include "memory/bios_memory_map.h"
#include <stdnoreturn.h>

noreturn void halt(void) {
    __asm__ volatile ("cli");
    for (;;)
        __asm__ volatile ("hlt");
}

int main(void) {
    TerminalInit();
    TerminalSetColor(TERMINAL_FORM_COLOR(kLightMagenta, kLightCyan));
    TerminalWriteString("Trans Rights!\n");

    struct RSDPExtended extended;
    if (!RSDPLocate(&extended)) {
        DebugCritical("Could not locate RSDP!");
        halt();
    }
    struct SDT rsdt;
    if (!RSDTRead(&extended.rsdp, &rsdt)) {
        DebugCritical("Could not read RSDT!");
        halt();
    }

    DebugInfo("Initializing IDT...");
    IDTInit();
    DebugSuccess("Initialized IDT!");

    DebugInfo("Reading Memory Map...");
    PopulateMemoryMap();
    DebugInfo("Base, Length, Type, Flags")
    for (size_t i = 0; i < MemoryMapEntries; i++) {
        struct MemoryMapEntry entry = MemoryMap[i];
        DebugInfoFormat("0x%dlx, 0x%dlx, %d, %d", entry.base, entry.length, entry.type, entry.flags);
    }

    /* TODO: PAGING and MADT
    if (CPUAPICSupported()) {
        DebugInfo("APIC supported, disabling 8259 PIC and enabling LAPIC and IOAPIC...");
        PICDisable();
        DebugSuccess("Disabled PIC!");
        
        struct SDT madt = {
            .type = kAPIC,
        };
        if (!SDTRead(&rsdt, &madt)) {
            DebugCritical("Failed to properly read MADT!");
            halt();
        }
        
    } else {
        DebugInfo("APIC not supported, enabling 8259 PIC...");
    }
    */

    return 0;
}
