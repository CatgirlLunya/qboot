#pragma once

#include "terminal/terminal.h"
#include "cpu/x86.h"

enum LogLevel {
    kSuccess = 0,
    kInfo,
    kWarn,
    kError,
    kCritical,
};

void DebugLog(enum LogLevel level, char* message);
#define DebugSuccess(msg) DebugLog(kSuccess, msg);
#define DebugInfo(msg) DebugLog(kInfo, msg); 
#define DebugWarn(msg) DebugLog(kWarn, msg);
#define DebugError(msg) DebugLog(kError, msg); 
#define DebugCritical(msg) DebugLog(kCritical, msg);

void DebugLogFormat(enum LogLevel level, char* format, ...);
#define DebugSuccessFormat(fmt, ...) DebugLogFormat(kSuccess, fmt, __VA_ARGS__)
#define DebugInfoFormat(fmt, ...) DebugLogFormat(kInfo, fmt, __VA_ARGS__)
#define DebugWarnFormat(fmt, ...) DebugLogFormat(kWarn, fmt, __VA_ARGS__)
#define DebugErrorFormat(fmt, ...) DebugLogFormat(kError, fmt, __VA_ARGS__)
#define DebugCriticalFormat(fmt, ...) DebugLogFormat(kCritical, fmt, __VA_ARGS__)

#define BochsBreak() outw(0x8A00,0x8A00); outw(0x8A00,0x08AE0);
