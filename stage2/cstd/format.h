#pragma once

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdarg.h>

// Callback functions primarily made for terminal functions to be easier and not need allocations
// May refactor this later if I dislike it, but so far its manageable
int FormatVarArgs(char* buffer, size_t length, char* format, va_list args);
int FormatVarArgsCallback(void(*callback)(char), char* format, va_list args);
int Format(char* buffer, size_t length, char* format, ...);
int FormatCallback(void(*callback)(char), char* format, ...);
