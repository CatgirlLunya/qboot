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
    MemoryMapPopulate();
    MemoryMapFix();
    uint64_t memory_to_manage = 0;
    DebugInfo("Base, Length, Type, Flags")
    for (size_t i = 0; i < MemoryMapEntries; i++) {
        struct MemoryMapEntry entry = MemoryMap[i];
        DebugInfoFormat("Memory Map Entry: %dlx, %dlx, %d, %d", entry.base, entry.length, entry.type, entry.flags);
        if (entry.base >= 0x100000 && entry.type == kUsableRAM) { // Past first megabyte
            memory_to_manage += entry.length;
        }
    }

    // Formula is weird to guarantee a round up
    uint64_t bytes_needed = (((memory_to_manage + 4095) / 4096 + 7) / 8);
    uint64_t page_frame_bitmap_address = 0;

    for (size_t i = 0; i < MemoryMapEntries; i++) {
        struct MemoryMapEntry entry = MemoryMap[i];
        if (entry.base >= 0x100000 && entry.type == kUsableRAM && entry.length >= bytes_needed) {
            page_frame_bitmap_address = entry.base;
            break;
        }
    }
    if (page_frame_bitmap_address == 0) {
        DebugCritical("Could not find a suitable page frame bitmap address!");
    }

    DebugInfoFormat("Found a page frame bitmap address: %dlx", page_frame_bitmap_address);
    
    struct MemoryMapEntry entry = {
        .base = page_frame_bitmap_address,
        .length = bytes_needed,
        .type = k32bitPageFrame,
        .flags = 1
    };
    (void)MemoryMapInsert(entry);
    MemoryMapFix();

    for (size_t i = 0; i < MemoryMapEntries; i++) {
        struct MemoryMapEntry entry = MemoryMap[i];
        DebugInfoFormat("Memory Map Entry: %dlx, %dlx, %d, %d", entry.base, entry.length, entry.type, entry.flags);
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
