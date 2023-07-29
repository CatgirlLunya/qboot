%ifdef DEBUG
section .data
%endif

global gdt ; for unit testing

gdt:
    ; acts as null segment and as pointer to save room
    .pointer:
        dw gdt.end - gdt.pointer ; doesn't compile right on elf32, so ignored in tests, but is consistently 0x18
        dd gdt
        dw 0

    ; These segments map out memory and replace real mode segmentation
    ; Segments are now indices to this table, rather than directly mapping to addresses
    ; The base is where each segment begins
    ; The limit is the maximum addressable unit, either in 1 byte or 4 KiB units
    ; 0x08 addresses this one, b/c it is [gdt+0x08]
    .code:
        dw 0xffff       ; Limit
        dw 0x0000       ; Base(lower 16 bits)
        db 0x00         ; Base(middle 8 bits)
        db 10011010b    ; Access(Valid segment, Code Segment, Readable)
        db 11001111b    ; Granularity(Lower 4 bits are limit, upper 4 say limit is by 4 KiB blocks and 32 bit segment)
        db 0x00         ; Base(high 8 bits)

    ; 0x10 addresses this
    .data:
        dw 0xffff
        dw 0x0000
        db 0x00
        db 10010010b    ; Same as above but Data segment
        db 11001111b
        db 0x0    

    .end:

section .text