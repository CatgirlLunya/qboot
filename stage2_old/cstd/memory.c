#include "memory.h"

void* MemoryCopy(void *restrict dst, const void *restrict src, size_t n) {
    unsigned char* dst_uc = (unsigned char*) dst;
	const unsigned char* src_uc = (const unsigned char*) src;
	if (dst < src) {
		while (n--) {
			*dst_uc++ = *src_uc++;
		}
	} else {
		unsigned char* dst_last_uc = (unsigned char*)dst + (n - 1);
		unsigned char* src_last_uc = (unsigned char*)src + (n - 1);
		while (n--) {
			*dst_last_uc-- = *src_last_uc--;
		}
	}

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

void* MemorySet(void* dst, uint8_t c, size_t n) {
	uint8_t* dst_uc = (uint8_t*)dst;
	for (size_t i = 0; i < n; i++) {
		dst_uc[i] = c;
	}
	return dst;
}
