#include "terminal/terminal.h"
#include "cpu/cpu.h"
#include "cpu/idt.h"

void test(void) {}

int main(void) {
    TerminalInit();
    TerminalSetColor(TerminalFormColor(kLightMagenta, kLightCyan));
    TerminalWriteString("Trans Rights!\n");

    struct Registers registers;
    if (!CPUID(0, &registers)) {
        TerminalWriteString("CPUID Failed!");
    } else {
        TerminalWriteString("Vendor ID: ");
        TerminalWriteStringLength((char*)&registers.ebx, 4);
        TerminalWriteStringLength((char*)&registers.edx, 4);
        TerminalWriteStringLength((char*)&registers.ecx, 4);
        TerminalWriteChar('\n');
    }

    IDTInit();

    extern void divide_by_zero(void);
    divide_by_zero();

    return 0;
}
