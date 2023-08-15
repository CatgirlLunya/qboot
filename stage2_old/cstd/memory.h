#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

void* MemoryCopy(void* dst, const void* src, size_t n);

int MemoryCompare(const void *s1, const void *s2, size_t n);

void* MemorySet(void* dst, uint8_t c, size_t n);
