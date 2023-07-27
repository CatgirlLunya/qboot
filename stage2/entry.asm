; Linker knows this is at 0x7E00 and 32 bit, specifying will give errors

extern main
extern bss_begin
extern bss_end

section .entry
global _start
_start:
    ; zeros out bss, c expects this
    cld
    xor al, al
    mov edi, bss_begin
    mov ecx, bss_end
    sub ecx, bss_begin
    rep stosb ; stosb puts al into edi then increments edi and decrements ecx
              ; rep loops until ecx is 0

    call main

    hang:     ; in case main somehow returns, dont reboot
        jmp hang
