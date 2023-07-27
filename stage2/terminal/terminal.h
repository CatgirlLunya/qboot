#pragma once

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#include "cpu/x86.h"

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

void TerminalInit(void);
uint8_t TerminalFormColor(enum TerminalColor foreground, enum TerminalColor background);
void TerminalPutCharAt(uint8_t character, uint8_t column, uint8_t row, uint8_t color);
void TerminalWriteChar(uint8_t character);
void TerminalWriteString(char* string);
void TerminalWriteStringLength(char* string, size_t length);
void TerminalWriteNumber(uint64_t number, int base);
void TerminalSetColor(uint8_t color);
void TerminalSetCursor(bool cursorEnabled);
void TerminalSetCursorPosition(uint8_t x, uint8_t y);

