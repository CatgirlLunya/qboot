#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

void* MemoryCopy(void *restrict dst, const void *restrict src, size_t n);

int MemoryCompare(const void *s1, const void *s2, size_t n);
