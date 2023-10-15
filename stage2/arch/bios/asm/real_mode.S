.section .realmode
.global biosInterrupt
.type biosInterrupt, @function
.code32

biosInterrupt:
    cli
    
    push %ebp
    push %ebx
    push %esi
    push %edi

    # modify the interrupt number
    # WARNING: SELF MODIFYING CODE USAGE
    movb 20(%esp), %al
    mov %al, interrupt_number(,1)

    # Save register input and output
    movl 24(%esp), %esi
    mov $register_buf, %edi
    mov $60, %ecx
    rep movsb

    movl 28(%esp), %eax
    mov %eax, out_register_pointer(,1)

    # Don't need to disable paging b/c this megabyte will be identity paged anyways

    sgdt (saved_gdt) # limine does this in case BIOS overwrites it, so I'm doing it too
    sidt (saved_idt)

    mov %esp, %ss:stack_pointer(,1) # Store old stack pointer, need to use esp in mainReal

    lidt real_idt

    # Uses 16 bit code segment of GDT
    jmp $0x18,$main16
main16:
    .code16
    mov $0x20, %ax
    mov %ax, %ds 
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs 
    mov %ax, %ss

    # Disable protected mode
    mov %cr0, %eax
    and $0xFE, %al
    mov %eax, %cr0
    # GDT doesn't work so we have to use code segment now, this put early on in linker to guarantee addresses work
    ljmp $0x0, $mainReal
mainReal:
    xor %ax, %ax
    mov %ax, %ss

    mov $register_buf, %esp
    pop %eax
    pop %ebx 
    pop %ecx 
    pop %edx 
    pop %edi
    pop %esi
    pop %ebp
    add $12, %esp
    # Skip esp to not interfere here
    # Skip 32 and 36 because those are stack segment and code segment
    pop %ds
    add $2, %esp
    pop %es
    add $2, %esp
    pop %fs
    add $2, %esp
    pop %gs
    add $2, %esp
    # pushl (%esp) # can't write to flags directly so do this
    # popfd

    mov %ss:stack_pointer(,1), %esp

    sti
    # Opcode for interrupt
    .byte 0xCD
    interrupt_number:
        .byte 0x0 # byte that stores interrupt number to use
    cli

    # Now fill out_registers
    mov $register_buf, %esp
    add $56, %esp
    # pushfd
    sub $2, %esp 
    push %gs
    sub $2, %esp
    push %fs
    sub $2, %esp
    push %es
    sub $2, %esp
    push %ds
    sub $12, %esp
    push %ebp
    push %esi
    push %edi
    push %edx
    push %ecx
    push %ebx
    push %eax

    lgdt %ss:saved_gdt
    lidt %ss:saved_idt

    mov %cr0, %eax
    or $0x1, %al
    mov %eax, %cr0
    ljmp $0x08, $end32
end32:
    .code32
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss

    mov $register_buf, %esi
    mov out_register_pointer(,1), %edi
    mov $60, %ecx
    rep movsb

    # Non-scratch registers
    mov %ss:stack_pointer(,1), %esp
    pop %edi
    pop %esi
    pop %ebx
    pop %ebp

    sti
    ret

.align 16
stack_pointer: .long 0
register_buf: .zero 60
out_register_pointer: .long 0
saved_gdt: .quad 0
saved_idt: .quad 0
real_idt:
    .short 0x3ff # Size
    .long 0     # Base

.section .text