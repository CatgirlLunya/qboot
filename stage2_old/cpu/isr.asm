%macro EXCEPTION_NOERR 1
    global exception%1
exception%1:
    cli
    push byte 0
    push byte %1
    jmp execution_handler
%endmacro

%macro EXCEPTION_ERR 1
    global exception%1
exception%1:
    cli
    push byte %1
    jmp execution_handler
%endmacro

EXCEPTION_NOERR 0
EXCEPTION_NOERR 1
EXCEPTION_NOERR 2
EXCEPTION_NOERR 3
EXCEPTION_NOERR 4
EXCEPTION_NOERR 5
EXCEPTION_NOERR 6
EXCEPTION_NOERR 7
EXCEPTION_ERR 8
EXCEPTION_NOERR 9
EXCEPTION_ERR 10
EXCEPTION_ERR 11
EXCEPTION_ERR 12
EXCEPTION_ERR 13
EXCEPTION_ERR 14
EXCEPTION_NOERR 15
EXCEPTION_NOERR 16
EXCEPTION_NOERR 17
EXCEPTION_NOERR 18
EXCEPTION_NOERR 19
EXCEPTION_NOERR 20
EXCEPTION_NOERR 21
EXCEPTION_NOERR 22
EXCEPTION_NOERR 23
EXCEPTION_NOERR 24
EXCEPTION_NOERR 25
EXCEPTION_NOERR 26
EXCEPTION_NOERR 27
EXCEPTION_NOERR 28
EXCEPTION_NOERR 29
EXCEPTION_NOERR 30
EXCEPTION_NOERR 31

extern CISRHandler

execution_handler:
    pusha

    ; don't need to worry about data segment like some interrupt handlers do 
    ; b/c not programming a full OS

    call CISRHandler

    popa
    add esp, 0x8 ; gets rid of error code and exception number on stack
    sti

    iret