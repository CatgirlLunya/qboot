; Uses int 10h, 0Eh
; The interrupt takes in a character in AL, so this function
; takes in a string pointer and loops through it, putting each character out
; Input:
;   - ds:si - pointer to null-terminated string
; Output:
;   - None
puts:
    push ax
    mov ah, 0Eh

    .loop:
        mov al, [si]
        inc si
        or al, al
        jz .end   ; null character
        int 10h
        jmp .loop

    .end:
        pop ax
        ret

; Uses puts, but indicates an error number
; Inputs:
;   - al - error number(0-9)
; Output:
;   - None
printError:
    add [msgError+7], al
    mov si, msgError
    call puts
    sub [msgError+7], al
    ret

; Error code added to 0x30 to give ASCII entry for digit
msgError: db "Error: ", 0x30, 0x0D, 0x0A, 0x0