/* 
Linker script partially inspired/stolen from limine bootloader
https://github.com/limine-bootloader/limine/blob/v5.x-branch/decompressor/linker.ld
*/

OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)
ENTRY(main)

PHDRS {
    text PT_LOAD FLAGS((1 << 0) | (1 << 2));
    data PT_LOAD FLAGS((1 << 1) | (1 << 2));
}

SECTIONS {
    . = 0x7E00; /* stage1 loads stage2 here */

    /* Puts the ".entry" section marked in main.zig first */ 
    .text : {
        *(.entry)
        *(.realmode)
        *(.text .text.*)
    } :text

    .data : {
        *(.rodata .rodata.*)
        *(.data .data.*)
    } :data

    .bss : {
        *(COMMON)
        *(.bss .bss.*)
    } :data

    /DISCARD/ : {
        *(.eh_frame)
        *(.note .note.*)
    }
}

/* TODO: Put in BIOS folder or make linker scripts folder */