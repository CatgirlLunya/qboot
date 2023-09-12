[org 0x7C00]
[bits 16]

boot:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    mov cx, 0 ; will use this for error handling, don't touch

    .initMsgs:
        mov si, msgBootInit
        call puts

    .checkDriveNumber:
        cmp dl, 80h
        jne error.invalidDrive

    .readStage2:
        .checkAvailable: ; need 13h extensions for this to work
            mov ah, 41h
            mov bx, 0x55aa
            int 13h
            jc error.int13hExtensions
            cmp bx, 0xaa55
            jne error.int13hExtensions
        ; Disk Packet - Needed for int 13h extensions
        disk_packet:
            .size: db 16
            .reserved: db 0
            .amt: dw 64 ; 64 sectors or 32 kb(max is 127 according to wikipedia, so making it clean)
            .offset: dw 0
            .segment: dw 0x7E0 ; segment to store stage2 at
            .loc: dq 2048 ; 2048 is the LBA
        
        mov al, 4 ; will loop twice, setting this up b/c i'll likely do this later anyways
        mov si, disk_packet
        mov ah, 42h ; int 13h, 42h is read

        .loop: 
            int 13h
            jc error.int13hFail ; carry set on interrupt fail, no space to add checks for output code
            add word [disk_packet.segment], 0x800
            sub al, 1
            test al, al
            jnz .loop

    mov si, msgLoadedStage2
    call puts

    call checka20
    jc .loadGDT

    .fasta20:
        in al, 0x92
        or al, 2
        and al, 0xFE    ; bit 0 must be 0
        out 0x92, al

    call checka20
    jnc error.a20Fail

    .loadGDT:
        lgdt [gdt]

    mov si, msgRealModePrep
    call puts

    .modifyCR0:
        cli
        mov eax, cr0
        or al, 1
        mov cr0, eax

    jmp 0x8:pmode

error:
    .invalidDrive:
        inc cx
    .int13hExtensions:
        inc cx
    .int13hFail:
        inc cx
    .a20Fail:
        inc cx

    mov ax, cx
    call printError

    .hang:
        jmp .hang

; Checks the status of the A20 line
; Does this by modifying 0xFFFF:0x7E0E 
; and checking if that changes 0x0000:0x7DFE
; Higher offset shifted by 16 bits b/c segment calculations
; Inputs:
;   - None
; Outputs:
;   - Carry flag set if enabled, cleared if disabled
checka20:
    push ax
    push ds
    push es
    push di
    push si

    xor ax, ax ; ds:si = 0x0000:0x7DFE, bootsector identifier
    mov ds, ax
    mov si, 0x7DFE

    not ax ; es:di = 0xFFFF:0x7E0E, 1 MB above
    mov es, ax
    mov di, 0x7E0E
    
    mov al, [ds:si]
    push ax

    mov al, [es:di]
    push ax

    mov byte [ds:si], 0x00
    mov byte [es:di], 0xFF

    cmp byte [ds:si], 0xFF
    stc
    jne .cleanup
    clc ; disabled if theyre equal, memory is wrapping around

    .cleanup:
        pop ax
        mov [ds:si], al

        pop ax
        mov [es:di], al
        
        pop si
        pop di
        pop es
        pop ds
        pop ax

        ret

%include "io.asm"

[bits 32]
pmode:
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov esp, 0x7FFFF ; As much free space for stack as possible, equal to (0x7FFFF - 0x7E00) - stage2 size

    jmp 0x7E00

hang:
    jmp hang

%include "gdt.asm"
msgBootInit: db "Bootloader started!", 0x0D, 0x0A, 0x0
msgLoadedStage2: db "Loaded stage2", 0x0D, 0x0A, 0x0
msgRealModePrep: db "Jumping to real mode...", 0x0D, 0x0A, 0x0
drvieNumber: db 0

times 446-($-$$) db 0