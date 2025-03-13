global myPrintfFunction

section .data
    ; bruh1 db 0
    ; helloMessage:           db "Hello C world, from asm world!", 10
    ; bruh2 db 0
    ; helloMessageLen         equ bruh1 - bruh2

    helloMessage:           db "Hello C world, from asm world!", 10
    helloMessageLen         equ 31




section .text

myPrintfFunction:
    mov rax, 0x01       ; syscall index of standard output function
    mov rdi, 1          ; file descriptor for stdout
    mov rsi, helloMessage
    mov rdx, helloMessageLen
    syscall

    ret

