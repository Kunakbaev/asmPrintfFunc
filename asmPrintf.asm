global myPrintfFunction

section .data
    ; bruh1 db 0
    ; helloMessage:           db "Hello C world, from asm world!", 10
    ; bruh2 db 0
    ; helloMessageLen         equ bruh1 - bruh2

    helloMessage:           db "Hello C world, from asm world!", 10
    helloMessageLen         equ 31
    MAX_TMP_BUFF_LEN        equ 100
    tmpStringBuff           db MAX_TMP_BUFF_LEN dup(0)




section .text

; rdx - string len
myPrint:
    mov rax, 0x01       ; syscall index of standard output function
    mov rdi, 1          ; file descriptor for stdout
    mov rsi, tmpStringBuff

    ; mov rdi, tmpStringBuff
    ; mov rcx, MAX_TMP_BUFF_LEN
    ; repne scasb
    ; sub rdi, tmpStringBuff ; save string len

    syscall
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

    push rsi
    mov rax, rdi
    call printNumberInDecimal

    mov rcx, 10
    pop rsi
    mov rdi, tmpStringBuff
    rep movsb
    mov rdx, 10
    call myPrint



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

