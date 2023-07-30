#include "debug.h"
#include "terminal/terminal.h"

uint16_t color_map[5] = {
    TERMINAL_FORM_COLOR(kLightGreen, kBlack),
    TERMINAL_FORM_COLOR(kWhite, kBlack),
    TERMINAL_FORM_COLOR(kYellow, kBlack),
    TERMINAL_FORM_COLOR(kLightRed, kBlack),
    TERMINAL_FORM_COLOR(kRed, kBlack),
};

char* message_map[5] = {
    "SUCCESS ",
    "INFO    ",
    "WARN    ",
    "ERROR   ",
    "CRITICAL"
};

void DebugLog(enum LogLevel level, char* message) {
    TerminalSetColor(TERMINAL_FORM_COLOR(kWhite, kBlack));
    TerminalWriteChar('[');
    TerminalSetColor(color_map[level]);
    TerminalWriteString(message_map[level]);
    TerminalSetColor(TERMINAL_FORM_COLOR(kWhite, kBlack));
    TerminalWriteString("] ");
    TerminalWriteString(message);
    TerminalWriteChar('\n');
}

void DebugLogFormat(enum LogLevel level, char* format, ...) {
    TerminalSetColor(TERMINAL_FORM_COLOR(kWhite, kBlack));
    TerminalWriteChar('[');
    TerminalSetColor(color_map[level]);
    TerminalWriteString(message_map[level]);
    TerminalSetColor(TERMINAL_FORM_COLOR(kWhite, kBlack));
    TerminalWriteString("] ");
    va_list list;
    va_start(list, format);
    TerminalFormatPrintVarArgs(format, list);
    va_end(list);
    TerminalWriteChar('\n');
}
