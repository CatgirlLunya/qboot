/* 
Linker script partially inspired/stolen from limine bootloader
https://github.com/limine-bootloader/limine/blob/v5.x-branch/decompressor/linker.ld
*/

OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)
ENTRY(_start)

PHDRS {
    text PT_LOAD FLAGS((1 << 0) | (1 << 2));
    data PT_LOAD FLAGS((1 << 1) | (1 << 2));
}

SECTIONS {
    . = 0x7E00; /* stage1 loads stage2 here */

    /* Puts the ".entry" section marked in entry.asm first */ 
    .text : {
        *(.entry)
        *(.text .text.*)
    } :text

    .data : {
        *(.rodata .rodata.*)
        *(.data .data.*)
    } :data

    .bss : {
        bss_begin = .; /* Given to entry.asm so it can zero out bss */
        *(COMMON)
        *(.bss .bss.*)
        bss_end = .; /* Same as above */
    } :data

    /DISCARD/ : {
        *(.eh_frame)
        *(.note .note.*)
    }
}