#pragma once

#include <stdint.h>

#include "memory/bios_memory_map.h"
#include "terminal/debug.h"

#define PAGE_SIZE 4096

int PageFrameAllocatorInit(void);
void PageFrameAllocatorSetPage(uint64_t page, bool used);

extern uint8_t* PageFrame;
extern uint64_t PageFrameEntries;
