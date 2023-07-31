#include "terminal.h"
#include "cstd/format.h"

static struct TerminalContext terminal_context;
volatile uint8_t* vgaBuffer = (uint8_t*)0xB8000;

void TerminalInit(void) {
    terminal_context.row = 0;
    terminal_context.column = 0;
    terminal_context.cursorEnabled = true;
    terminal_context.color = TERMINAL_FORM_COLOR(kWhite, kBlack);
    TerminalSetCursor(terminal_context.cursorEnabled);
    TerminalSetCursorPosition(0, 0);

    for (int y = 0; y < 25; y++) {
        for (int x = 0; x < 80; x++) {
            TerminalPutCharAt(0, x, y, 0);
        }
    }
}

void TerminalNewline(void) {
    if (terminal_context.row < 24) {
        terminal_context.row++;
    } else {
        MemoryCopy((void*)vgaBuffer, (void*)&vgaBuffer[80*2], 80*24*2);
    }
    MemorySet((void*)&vgaBuffer[80*24*2], '\0', 80*2);
    terminal_context.column = 0;
}

void TerminalPutCharAt(uint8_t character, uint8_t column, uint8_t row, uint8_t color) {
    size_t index = ((size_t)row * 80 + (size_t)column) * 2;
    vgaBuffer[index] = character;
    vgaBuffer[index+1] = color;
    TerminalSetCursorPosition(column, row);
}

void TerminalWriteChar(char character) {
    if (character == '\0') return;
    else if (character == '\n') {
        TerminalNewline();
    } else {
        TerminalPutCharAt((uint8_t)character, terminal_context.column, terminal_context.row, terminal_context.color);
        terminal_context.column++;
        if (terminal_context.column > 80) {
            terminal_context.column -= 80;
            terminal_context.row++;
        }
    }
}

void TerminalWriteString(char* string) {
    while (*string != 0) {
        TerminalWriteChar(*string);
        string++;
    }
}

void TerminalFormatPrintVarArgs(char* format, va_list args) {
    (void)FormatVarArgsCallback(TerminalWriteChar, format, args);
}

void TerminalFormatPrint(char* format, ...) {
    va_list list;
    va_start(list, format);
    (void)FormatVarArgsCallback(TerminalWriteChar, format, list);
    va_end(list);
}

void TerminalWriteStringLength(char *string, size_t length) {
    size_t i = 0;
    while (i < length) {
        TerminalWriteChar(string[i]);
        i++;
    }
}

void TerminalSetColor(uint8_t color) {
    terminal_context.color = color;
}

void TerminalSetCursor(bool cursorEnabled) {
    if (cursorEnabled) {
        // Tells the CRT Controller Address Register(0x3D4) that we will write to the Cursor Start Register(0xA)
        outb(0x3D4, 0x0A);
        // Gives the CRT Controller Data Register(0x3D5) a byte which
        // enables the cursor(sets the 3rd bit to 0) and sets the starting scanline to 14
        outb(0x3D5, 0x0E);  

        // Does the same as above but with the Cursor End Register(0xB)
        outb(0x3D4, 0x0B);
        // Also same as above but scanline 15 is end line
        outb(0x3D5, 0x0F);
    } else {
        // Writes 0b0010000 to start register, disabling cursor
        outb(0x3D4, 0x0A);
        outb(0x3D5, 0x20);
    }
}

void TerminalSetCursorPosition(uint8_t x, uint8_t y) {
    uint16_t position = y * 80 + x;
    outb(0x3D4, 0x0F); // Cursor location low register
    outb(0x3D5, (uint8_t) (position & 0xFF));
    outb(0x3D4, 0x0E); // Cursor location high register
    outb(0x3D5, (uint8_t) ((position >> 8) & 0xFF));
}
