#include "string.h"

size_t strlen(char* s) {
    size_t size = 0;
    while (*s != 0) {
        size++;
        s++;
    }
    return size;
}
