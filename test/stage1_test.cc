#include "gtest/gtest.h"
#include <gtest/gtest.h>
#include <cstdint>
#include <iostream>

union GDTEntry {
    uint64_t entry;
    struct {
        uint16_t limit;
        uint16_t base_lower;
        uint8_t base_middle;
        uint8_t access;
        uint8_t granularity;
        uint8_t base_upper;
    }__attribute__((packed));
    struct {
        uint16_t size;
        uint32_t pointer;
        uint16_t reserved;
    }__attribute__((packed));

    bool operator==(union GDTEntry other) const {
        return entry == other.entry;
    }
}__attribute__((packed));

extern GDTEntry gdt[3];

TEST(STAGE1_TEST, GDT) {
    ASSERT_EQ((uint32_t)gdt, gdt[0].pointer) << "GDT pointer not equal to GDT location!";
    union GDTEntry code_segment = {
        .limit = 0xFFFF,
        .base_lower = 0x0000,
        .base_middle = 0x00,
        .access = 0b10011010,
        .granularity = 0b11001111,
        .base_upper = 0x00,
    };

    ASSERT_EQ(gdt[1], code_segment);

    union GDTEntry data_segment = code_segment;
    data_segment.access = 0b10010010;

    ASSERT_EQ(gdt[2], data_segment);
}