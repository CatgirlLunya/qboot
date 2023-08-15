section .realmode ; limine uses this, assuming I should too
[bits 32]

global BIOSInterrupt
BIOSInterrupt:
    cli

    ; modify the interrupt number
    ; WARNING: SELF MODIFYING CODE USAGE
    mov al, byte [esp+4]
    mov [.interrupt_number], al

    ; Save register input and output
    mov eax, dword [esp+8]
    mov dword [storage.out_registers], eax

    mov eax, dword [esp+12]
    mov dword [storage.in_registers], eax

    ; Don't need to disable paging b/c this megabyte will be identity paged anyways

    sgdt [storage.saved_gdt] ; limine does this in case BIOS overwrites it, so I'm doing it too
    sidt [storage.saved_idt]

    push ebx
    push esi
    push edi
    push ebp

    ; Uses 16 bit code segment of GDT
    jmp 0x18:.main16
.main16:
    [bits 16]
    mov ax, 0x20
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; OSDev wiki says do this before disabling protected mode but while in 16 bit
    lidt [storage.real_idt]

    ; Disable protected mode
    mov eax, cr0
    and al, 0xFE
    mov cr0, eax
    ; GDT doesn't work so we have to use code segment now, this put early on in linker to guarantee addresses work
    jmp 0x00:.mainReal
.mainReal:
    xor ax, ax
    mov ss, ax

    mov dword [ss:storage.stack_pointer], esp ; store stack pointer so we can pop all of the registers from in_registers
    mov esp, dword [ss:storage.in_registers]
    mov gs, [esp]
    mov fs, [esp+2]
    mov es, [esp+4]
    mov ds, [esp+6]
    push dword [esp+8] ; can't write to flags directly so do this
    popf
    mov esp, dword [ss:storage.in_registers]
    mov ebp, [esp+12]
    mov edi, [esp+16]
    mov esi, [esp+20]
    mov edx, [esp+24]
    mov ecx, [esp+28]
    mov ebx, [esp+32]
    mov eax, [esp+36]
    mov esp, dword [ss:storage.stack_pointer]

    sti
    ; Opcode for interrupt
    db 0xCD
    .interrupt_number:
        db 0 ; byte that stores interrupt number to use
    cli

    ; Now fill out_registers
    mov dword [ss:storage.stack_pointer], esp
    mov esp, dword [ss:storage.out_registers]
    mov [esp+36], eax
    mov [esp+32], ebx
    mov [esp+28], ecx
    mov [esp+24], edx
    mov [esp+20], esi
    mov [esp+16], edi
    mov [esp+12], ebp
    add esp, 8 ; TODO: FIX, currently broken
    pushf
    mov esp, dword [ss:storage.out_registers]
    mov [esp+6], ds
    mov [esp+4], es
    mov [esp+2], fs
    mov [esp], gs

    mov esp, dword [ss:storage.stack_pointer]

    lgdt [ss:storage.saved_gdt]
    lidt [ss:storage.saved_idt]

    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp 0x08:.end32
.end32:
    [bits 32]
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Non-scratch registers
    pop ebp
    pop edi
    pop esi
    pop ebx

    ret

storage:
    .stack_pointer: dd 0
    .out_registers: dd 0
    .in_registers: dd 0
    .saved_gdt: dq 0
    .saved_idt: dq 0
    .real_idt:
        dw 0x3ff ; Size
        dd 0     ; Base