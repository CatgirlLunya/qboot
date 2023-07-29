#include "memory.h"

void* MemoryCopy(void *restrict dst, const void *restrict src, size_t n) {
    unsigned char* dst_uc = (unsigned char*) dst;
	const unsigned char* src_uc = (const unsigned char*) src;

    for (size_t i = 0; i < n; i++)
        dst_uc[i] = src_uc[i];

    return dst;
}

int MemoryCompare(const void *s1, const void *s2, size_t n) {
    const unsigned char* a = (const unsigned char*) s1;
	const unsigned char* b = (const unsigned char*) s2;
	for (size_t i = 0; i < n; i++) {
		if (a[i] < b[i])
			return -1;
		else if (b[i] < a[i])
			return 1;
	}
	return 0;
}
