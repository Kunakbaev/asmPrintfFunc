global myPrintfFunction

section .data
    MAX_FORMAT_STR_BUFF_LEN     equ 100
    helloMessageLen             equ 31
    MAX_TMP_BUFF_LEN            equ 100
    FORMAT_STRING_DELIM         equ '%'
    ERROR_EXIT_CODE             equ 228

    helloMessage:               db "Hello C world, from asm world!", 10
    tmpStringBuff               db MAX_TMP_BUFF_LEN dup(0)
    formatStringBuff            db MAX_FORMAT_STR_BUFF_LEN dup(0)
    errorMessage                db "Some error has occured(", 10
    errorMessageLen             db 24
    newLine                     db 10





section .text

exitProgrammWithError:
    mov eax, 0x3C
    mov ebx, ERROR_EXIT_CODE

    syscall
    ret ; ???

; entry: RDX - string len
;        RSI - address of source string
;
myPrint:
    mov rax, 0x01               ; syscall index of standard output function
    mov rdi, 1    ; file descriptor for stdout

    syscall
    ret

printNewLine:
    mov rdx, 1
    mov rsi, newLine
    call myPrint
    ret

showErrorMessage:
    mov rsi, errorMessage
    mov rdx, errorMessageLen

    call myPrint
    call exitProgrammWithError

    ret

; rax number
printNumberInDecimal:
    mov rdi, tmpStringBuff
    xor rcx, rcx

    digitLoop:
        mov rbx, 10
        xor rdx, rdx
        div rbx ; reminder to edx
        push rax
        mov rax, rdx
        add rax, '0'
        stosb
        pop rax

        inc rcx
        cmp rax, 0
        jne digitLoop

    mov rdx, rcx
    mov rsi, tmpStringBuff
    call myPrint

    ret


myPrintfFunction:
;     push rbp
;     mov rbp, rsp
; ;
    ; mov rdi, [rbp-8]
    ; mov rsi, [rbp-16]
    ; push rsi

    ; mov rdx, helloMessageLen
    ; mov rcx, rdx
    ; mov rsi, helloMessage
    ; mov rdi, tmpStringBuff
    ; rep movsb
    ; call myPrint

    ; mov rax, 22891
    ; mov rdx, dword edi
    ; mov rax, rdi
    ; call printNumberInDecimal

;     push rsi
;     mov rax, rdi
;     call printNumberInDecimal
;
;     mov rcx, 10
;     pop rsi
;     mov rdi, tmpStringBuff
;     rep movsb
;     mov rdx, 10
;     call myPrint



    mov rsi, rdi
    formatStringCharsLoop:
        xor eax, eax
        lodsb
        cmp al, 0
        je formatStringLoopEnd ; c string is terminated with \0
        cmp al, FORMAT_STRING_DELIM
        ; je validFormatDelimeter
        ;     call showErrorMessage
        ; validFormatDelimeter:

        xor eax, eax
        lodsb
        push rsi
        call printNumberInDecimal
        call printNewLine
        pop rsi


        jmp formatStringCharsLoop
    formatStringLoopEnd:



;     mov rdx, helloMessageLen
;     mov rcx, rdx
;     mov rsi, helloMessage
;     mov rdi, tmpStringBuff
;     rep movsb
;     call myPrint
;
;     ;pop rsi
;     mov rdx, rsi
;     call printNumberInDecimal

    ; mov rax, 0x01       ; syscall index of standard output function
    ; mov rdi, 1          ; file descriptor for stdout
    ; mov rsi, helloMessage
    ; mov rdx, helloMessageLen
    ; syscall

    ;pop rbp
    ret

