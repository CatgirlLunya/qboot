#pragma once

#include <stdint.h>
#include <stdbool.h>

#include "memory/bios_memory_map.h"
#include "terminal/debug.h"

#define PAGE_SIZE 4096

// TODO: Normalize all the integer types for cleaner, more sensical code
int PageFrameAllocatorInit(void);
void PageFrameAllocatorSetPage(uint64_t page, bool used);
bool PageFrameAllocatorGetPage(uint64_t page);
uint8_t* PageFrameAllocatePages(uint64_t pages);
void PageFrameFreePages(uint8_t* page_ptr, uint64_t pages);
uint8_t* PageFrameAllocate(uint64_t bytes);
void PageFrameFree(uint8_t* ptr);

extern uint8_t* PageFrame;
extern uint64_t PageFrameEntries;
extern uint64_t NextPage;
