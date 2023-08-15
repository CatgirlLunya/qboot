#pragma once

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdarg.h>

#include "cstd/math.h"
#include "cstd/memory.h"
#include "cstd/type.h"

// Callback functions primarily made for terminal functions to be easier and not need allocations
// May refactor this later if I dislike it, but so far its manageable
size_t FormatVarArgs(char* buffer, size_t length, char* format, va_list args);
size_t FormatVarArgsCallback(void(*callback)(char), char* format, va_list args);
size_t Format(char* buffer, size_t length, char* format, ...);
size_t FormatCallback(void(*callback)(char), char* format, ...);
