#include "terminal/debug.h"
#include "terminal/terminal.h"
#include "cpu/cpu.h"
#include "cpu/idt.h"
#include "cpu/lapic.h"
#include "cpu/pic.h"
#include "cpu/rsdt.h"
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
    RSDTLocateRSDP(&extended);
    DebugInfoFormat("RSDP Format: %d\n", extended.rsdp.revision);

    DebugInfo("Initializing IDT...");
    IDTInit();
    DebugSuccess("Initialized IDT!");

    if (CPUAPICSupported()) {
        DebugInfo("APIC supported, disabling 8259 PIC and enabling LAPIC and IOAPIC...");
        PICDisable();
        DebugSuccess("Disabled PIC!");

        union LAPICStatus status = LAPICGetStatus();
        status.enabled = true;
        LAPICSetStatus(status);
    } else {
        DebugInfo("APIC not supported, enabling 8259 PIC...");
    }

    return 0;
}
