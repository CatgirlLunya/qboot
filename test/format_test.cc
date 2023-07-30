#include <gtest/gtest.h>
#include <cstdint>
#include <iostream>

extern "C" {
    #include "cstd/format.h"
}

TEST(FORMAT, UINT32) {
    char buffer[64];
    Format(buffer, 10, (char*)"%d", UINT32_C(123456789));
    ASSERT_STREQ(buffer, "123456789");
}

TEST(FORMAT, UINT64) {
    char buffer[64];
    Format(buffer, 19, (char*)"%dl", UINT64_C(123456789123456789));
    ASSERT_STREQ(buffer, "123456789123456789");
}

TEST(FORMAT, HEX) {
    char buffer[64];
    Format(buffer, 17, (char*)"%dlx", UINT64_C(0x123456789ABCDEF0));
    ASSERT_STREQ(buffer, "123456789ABCDEF0");
}

TEST(FORMAT, BINARY) {
    char buffer[64];
    Format(buffer, 65, (char*)"%db", UINT32_C(0b10101001));
    ASSERT_STREQ(buffer, "10101001");
}

char* test_cb_memory = new char[64];

static void test_cb(char c) {
    static size_t index = 0;
    test_cb_memory[index++] = c;
}

TEST(FORMAT, CALLBACK) {
    FormatCallback(test_cb, (char*)"%d", UINT32_C(12345678));
    ASSERT_STREQ(test_cb_memory, "12345678");
}

TEST(FORMAT, COMBINED) {
    char buffer[64];
    Format(buffer, 64, (char*)"Number: %d\n", UINT32_C(123456));
    ASSERT_STREQ(buffer, "Number: 123456\n");
}

TEST(FORMAT, MEMORY) {
    char buffer[64];
    char mem[4] = {0x12, 0x34, 0x56, 0x78};
    Format(buffer, 64, (char*)"Memory: %mx4 :Memory", mem);
    ASSERT_STREQ(buffer, "Memory: 12 34 56 78 :Memory");
    uint8_t mem2[10] = {11, 22, 33, 44, 55, 66, 77, 88, 99, 111};
    Format(buffer, 64, (char*)"Memory: %m10 :Memory", mem2);
    ASSERT_STREQ(buffer, "Memory: 11 22 33 44 55 66 77 88 99 111 :Memory");
}
