#pragma once

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>

#include "cpu/x86.h"
#include "cstd/format.h"

struct TerminalContext {
    uint8_t column;
    uint8_t row;
    uint8_t cursorColumn;
    uint8_t cursorRow;
    bool cursorEnabled;
    uint8_t color; // stores current color for writing
};

enum TerminalColor{
    kBlack = 0,
    kBlue = 1,
    kGreen = 2,
    kCyan = 3,
    kRed = 4,
    kMagenta = 5,
    kBrown = 6,
    kLightGray = 7,
    kDarkGray = 8,
    kLightBlue = 9,
    kLightGreen = 10,
    kLightCyan = 11,
    kLightRed = 12,
    kLightMagenta = 13,
    kYellow = 14,
    kWhite = 15,
};

#define TERMINAL_FORM_COLOR(foreground, background) (foreground | (background << 4))

void TerminalInit(void);
void TerminalNewline(void);
void TerminalPutCharAt(uint8_t character, uint8_t column, uint8_t row, uint8_t color);
void TerminalWriteChar(char character);
void TerminalWriteString(char* string);
void TerminalWriteStringLength(char* string, size_t length);
void TerminalFormatPrintVarArgs(char* format, va_list args);
void TerminalFormatPrint(char* format, ...);
void TerminalSetColor(uint8_t color);
void TerminalSetCursor(bool cursorEnabled);
void TerminalSetCursorPosition(uint8_t x, uint8_t y);

