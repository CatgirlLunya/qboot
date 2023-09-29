.section .realmode
.global biosInterrupt
.type biosInterrupt, @function
.code32

biosInterrupt:
    cli

    # modify the interrupt number
    # WARNING: SELF MODIFYING CODE USAGE
    movb 4(%esp), %al
    movb %al, (interrupt_number)

    # Save register input and output
    movl 8(%esp), %eax
    movl %eax, (in_registers)

    movl 12(%esp), %eax
    movl %eax, (out_registers)

    push %ebx
    push %esi
    push %edi
    push %ebp

    # Don't need to disable paging b/c this megabyte will be identity paged anyways

    sgdt (saved_gdt) # limine does this in case BIOS overwrites it, so I'm doing it too
    sidt (saved_idt)

    movl %esp, %ss:stack_pointer

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
    jmp $0x0, $mainReal
mainReal:
    xor %ax, %ax
    mov %ax, %ss

    movl %esp, %ss:stack_pointer # store stack pointer so we can pop all of the registers from in_registers
    movl %ss:in_registers, %esp
    mov (%esp), %eax
    mov 4(%esp), %ebx
    mov 8(%esp), %ecx
    mov 12(%esp), %edx
    mov 16(%esp), %edi
    mov 20(%esp), %esi
    mov 24(%esp), %ebp
    # Skip esp to not interfere here
    # Skip 32 and 36 because those are stack segment and code segment
    mov 40(%esp), %ds
    mov 44(%esp), %es
    mov 48(%esp), %fs
    mov 52(%esp), %gs
    pushl 56(%esp) # can't write to flags directly so do this
    popfd
    movl %ss:stack_pointer, %esp

    sti
    # Opcode for interrupt
    .byte 0xCD
    interrupt_number:
        .byte 0x0 # byte that stores interrupt number to use
    cli

    # Now fill out_registers
    movl %esp, %ss:stack_pointer
    movl %ss:out_registers, %esp
    mov %eax, (%esp)
    mov %ebx, 4(%esp)
    mov %ecx, 8(%esp)
    mov %edx, 12(%esp)
    mov %edi, 16(%esp)
    mov %esi, 20(%esp)
    mov %ebp, 24(%esp)
    movl %ss:stack_pointer, %eax
    mov %eax, 28(%esp)
    mov %ds, 40(%esp)
    mov %es, 44(%esp)
    mov %fs, 48(%esp)
    mov %gs, 52(%esp)
    add $0x52, %esp
    pushfd

    movl %ss:stack_pointer, %esp

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

    # Non-scratch registers
    pop %ebp
    pop %edi
    pop %esi
    pop %ebx

    sti
    ret

stack_pointer: .long 0
out_registers: .long 0
in_registers: .long 0
saved_gdt: .quad 0
saved_idt: .quad 0
real_idt:
    .short 0x3ff # Size
    .long 0     # Base