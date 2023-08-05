#include "page_frame_allocator.h"
#include "memory/bios_memory_map.h"

uint8_t* PageFrame = NULL;
uint64_t PageFrameEntries = 0;
uint64_t NextPage = 0;

bool PageFrameAllocatorGetPage(uint64_t page) {
    return PageFrame[page/8] & (1 << (page % 8));
}

void PageFrameAllocatorSetPage(uint64_t page, bool used) {
    if (PageFrame == NULL) return;
    if (used)
        PageFrame[page/8] |= (1 << (page % 8));
    else
        PageFrame[page/8] &= ~((uint8_t)(1 << (page % 8)));
}

int PageFrameAllocatorInit(void) {
    // Get as much RAM as we need to handle, divide it into pages(4096), divide that so 8 pages per byte
    // Formula has addition to make sure we round up
    uint64_t pages_required = ((MemoryMapRAMCount32Bit() + 4095) / 4096);
    uint64_t bytes_required = (pages_required + 7) / 8;
    size_t map_entry = MemoryMapReserve(bytes_required);
    if (map_entry == (size_t)-1) return 0;
    MemoryMap[map_entry].type = k32bitPageFrame;
    // GCC gets angry if I try to use a 64 bit value for a pointer on a 32 bit compiler
    PageFrame = (uint8_t*)((uint32_t)MemoryMap[map_entry].base);
    PageFrameEntries = bytes_required;
    for (uint64_t page = 0; page < pages_required; page++) {
        PageFrameAllocatorSetPage(page, true); // Everything is set to "used" by default, only guaranteed to be safe memory locations allowed
        if (page <= 0x100 || page >= 0x100000) continue; // Page is out of the first megabyte and in the first 4 gb
        for (size_t memmap_entry = 0; memmap_entry < MemoryMapEntries; memmap_entry++) {
            // Checks if page is fully inside a Usable RAM memory entry
            if (MemoryMap[memmap_entry].type != kUsableRAM) continue;
            if (MemoryMap[memmap_entry].base > (page * PAGE_SIZE) || MemoryMap[memmap_entry].base + MemoryMap[memmap_entry].length < (((page+1) * PAGE_SIZE) - 1)) continue;
            PageFrameAllocatorSetPage(page, false);
        }
    }

    return 1;
}

uint64_t SearchForPageBlock(uint64_t pages, uint64_t start, uint64_t limit) {
    for (uint64_t page = start; page < limit; page++) {
        bool usable = true;
        for (uint64_t i = 0; i < pages; i++) {
            if (PageFrameAllocatorGetPage(page+i)) {
                usable = false;
                page += i;
                break;
            }
        }
        if (usable) {
            return page;
        }
    }

    return 0;
}

uint8_t* PageFrameAllocatePages(uint64_t pages) {
    uint64_t page_block = SearchForPageBlock(pages, NextPage, PageFrameEntries);
    if (page_block == 0) {
        page_block = SearchForPageBlock(pages, 0, NextPage);
    }

    if (page_block == 0) return 0;

    NextPage = page_block + pages;
    for (uint64_t page = 0; page < pages; page++) {
        PageFrameAllocatorSetPage(page_block+page, true);
    }
    return (uint8_t*)((size_t)(page_block * PAGE_SIZE));
}
