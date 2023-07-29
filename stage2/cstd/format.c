#include "format.h"

// Takes in a uint64_t, a base, and a buffer with a max length to put the string in
// Returns how many characters were written
size_t uint64_to_string(uint64_t x, int base, char* buffer, size_t length) {
    uint64_t temp;
    size_t i = 0;

    do {
        if (i == length) break; 
        temp = x % base;
        // This line converts each digit into a displayable char
        buffer[i++] = (temp < 10) ? (temp + '0') : (temp + 'A' - 10);
    } while (x /= base); // Goes through each digit until number goes to 0
    i--; // i now points to final digit

    size_t written = i + 1; // Save for return
    // The numbers go the opposite order they should, this fixes it
    for (size_t j = 0; j < i; j++, i--) {
        temp = buffer[j];
        buffer[j] = buffer[i];
        buffer[i] = temp;
    }

    return written;
}

// This big function is private but takes in either a buffer/length pair or a callback along with a format and va_list, to be as generically used as possible
// If callback isn't NULL it uses that
// Wish I had lambdas for this holy shit
int FormatVarArgsCallbackOrBuffer(char* buffer, size_t length, void(*callback)(char), char* format, va_list list) {
    static char temp_buf[65]; // For numbers b/c I don't feel like generalizing that function too
    size_t buffer_pos = 0;
    if (length == 0) length = 0xFFFFFFF;
    while (*format != '\0') {
        size_t remaining = length - buffer_pos;
        if (remaining == 1) break;
        if (*format != '%') {
            if (callback != NULL) {
                callback(*format);
            } else {
                buffer[buffer_pos] = *format;
            }
            buffer_pos++;
            format++;
            continue;
        }
        format++;
        switch (*format++) {
            case 'i':
            case 'd': {
                size_t base = 10;
                bool big = false; // uint32_t or uint64_t
                while (*format == 'l' || *format == 'x' || *format == 'b') {
                    switch (*format) {
                        case 'l':
                            big = true;
                            break;
                        case 'x':
                            base = 16;
                            break;
                        case 'b':
                            base = 2;
                            break;
                    }   
                    format++;
                }

                uint64_t number;
                if (big) number = (uint64_t)va_arg(list, uint64_t);
                else number = va_arg(list, uint32_t);

                size_t written;
                if (callback != NULL) {
                    written = uint64_to_string(number, base, temp_buf, 65);
                    for (size_t i = 0; i < written; i++) callback(temp_buf[i]);
                } else {
                    written = uint64_to_string(number, base, &buffer[buffer_pos], remaining);
                }
                buffer_pos += written;
                break;
            }
        }
    }
    if (callback != NULL) {
        callback('\0');
    } else {
        buffer[buffer_pos] = '\0';
    }
    return buffer_pos;
}

int FormatVarArgs(char* buffer, size_t length, char* format, va_list args) {
    return FormatVarArgsCallbackOrBuffer(buffer, length, NULL, format, args);
}

int FormatVarArgsCallback(void(*callback)(char), char* format, va_list args) {
    return FormatVarArgsCallbackOrBuffer(NULL, 0, callback, format, args);
}

int Format(char* buffer, size_t length, char* format, ...) {
    va_list args;
    va_start(args, format);
    int ret = FormatVarArgsCallbackOrBuffer(buffer, length, NULL, format, args);
    va_end(args);
    return ret;
}

int FormatCallback(void(*callback)(char), char* format, ...) {
    va_list args;
    va_start(args, format);
    int ret = FormatVarArgsCallbackOrBuffer(NULL, 0, callback, format, args);
    va_end(args);
    return ret;
}
