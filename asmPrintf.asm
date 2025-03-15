global myPrintfFunction

extern printf
extern atexit

section .data
    MAX_FORMAT_STR_BUFF_LEN     equ 100
    MAX_TMP_BUFF_LEN            equ 100
    DECIMAL_FORMAT_STRING       equ 'd'
    BOOL_FORMAT_STRING          equ 'b'
    OCTAL_FORMAT_STRING         equ 'o'
    HEX_FORMAT_STRING           equ 'x'
    CHAR_FORMAT_STRING          equ 'c'
    STRING_FORMAT_STRING        equ 's'
    FORMAT_STRING_DELIM         equ '%'
    ERROR_EXIT_CODE             equ 228
    TRUE_STRING_LEN             equ 4
    FALSE_STRING_LEN            equ 5
    MAX_OUTPUT_BUFFER_LEN       equ 10

    tmpStringBuff               db MAX_TMP_BUFF_LEN dup(0)
    formatStringBuff            db MAX_FORMAT_STR_BUFF_LEN dup(0)
    errorMessage                db "Some error has occured(", 10
    errorMessageLen             equ 24
    newLine                     db 10
    trueString                  db "true"
    falseString                 db "false"

    outputBufferString          db MAX_OUTPUT_BUFFER_LEN dup(0)
    numOfCharsInOutputBuffer    dd 0






section .text

exitProgrammWithError:
    mov eax, 0x3C
    mov ebx, ERROR_EXIT_CODE

    syscall
    ret ; ???

; entry: RDX - string len
;        RSI - address of source string
clearAndOutputBuffer:
    push rdi
    push rsi
    push rdx
    push rax

;     mov rax, 0x01 ; syscall index of standard output function
;     mov rdi, 1    ; file descriptor for stdout
;     mov rsi, trueString
;     mov rdx, TRUE_STRING_LEN
;
;     syscall



    mov rax, 0x01 ; syscall index of standard output function
    mov rdi, 1    ; file descriptor for stdout
    mov rsi, outputBufferString

    mov rdx, [numOfCharsInOutputBuffer] ; len of buffer
    ; numOfCharsInOutputBuffer = 0
    mov word [numOfCharsInOutputBuffer], 0

    syscall
    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

; entry: AL - char to add
addChar2Buffer:
    push rdi
    push rax
    push rbx
    push rcx

    xor rbx, rbx
    mov rdi, outputBufferString
    mov ebx, [numOfCharsInOutputBuffer]
    add rdi, rbx
    stosb
    ; inc

    mov eax, [numOfCharsInOutputBuffer]
    inc eax
    mov dword [numOfCharsInOutputBuffer], eax

    cmp eax, MAX_OUTPUT_BUFFER_LEN
    jne notYetTimeToFlush
        call clearAndOutputBuffer
    notYetTimeToFlush:

    pop rcx ; ASK: who did change rcx?
    pop rbx
    pop rax
    pop rdi
    ret

; printNewLine:
;     mov rdx, 1
;     mov rsi, newLine
;     call myPrint
;     ret

; showErrorMessage:
;     mov rsi, errorMessage
;     mov rdx, errorMessageLen
;
;     call myPrint
;     call exitProgrammWithError
;
;     ret

; we consider that base is <= 255
; entry: RBX base
;        RAX number
printNumberInSomeBase:
    push rcx
    push rdx
    push rax
    push rdi

    xor rcx, rcx
    digitLoop:
        xor rdx, rdx
        div rbx ; reminder to edx
        push rax
        mov rax, rdx

        cmp ax, 10
        jl reminderIsDigit
            add ax, 'A' - 10
            jmp reminderIsDigitIfEnd
        reminderIsDigit:
            add ax, '0'
        reminderIsDigitIfEnd:
        mov dx, ax
        pop rax
        push dx

        inc rcx
        cmp rax, 0
        jne digitLoop

    digitOutputLoop:
        pop ax
        call addChar2Buffer
        loop digitOutputLoop

    pop rdi
    pop rax
    pop rdx
    pop rcx
    ret

; ENTRY: al - char to print
printSingleChar:
    call addChar2Buffer
    ret

; ENTRY: rax - address of a string
printString:
    push rsi
    push rdi

    push rax ; save string address
    xor rdx, rdx ; rdx = 0
    sub rdx, rax ; prepare string len reg

    mov rdi, rax ; load string address
    mov rcx, 100 ; max string len
    mov al, 0
    repne scasb ; search for terminating char
    add rdx, rdi

    ; ; print string len
    ; mov rbx, 10
    ; mov rax, rdx
    ; call printNumberInSomeBase

    pop rsi ; restore string address
    ; call myPrint

    pop rdi
    pop rsi
    ret

; ENTRY: rax - variable
printBoolean:
    push rsi
    push rdx

    cmp rax, 1
    je valIsTrue
        mov rdx, FALSE_STRING_LEN
        mov rsi, falseString
        ;call myPrint
        jmp valIsTrueIfEnd
    valIsTrue:
        mov rdx, TRUE_STRING_LEN
        mov rsi, trueString
        ;call myPrint
    valIsTrueIfEnd:

    pop rdx
    pop rsi
    ret

; System V calling convention (first 6 args are passed through registers and remaining are put to the stack)
myPrintfFunction:
    ;and rsp,-16
    ; push rdi
    ; ;sub rsp, 8
    ; mov rdi, trueString
    ; call printf
    ; ;add rsp, 8
    ; pop rdi
    ; ;ret

    ; For now function only accepts arguments of INTEGER types (addresses, chars, ints)
    ; each argument is rounded up to 8 bytes
    ; arguments are put to registers in that order: RDI, RSI, RDX, RCX, R8, R9
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    ; calling C function atexit, to set function that will be called at the end
    ; ASK: how does it work? what if my function overwrites smth important?
    sub rsp, 8
    mov rdi, clearAndOutputBuffer
    call atexit
    add rsp, 8

    call myPrintfFunctionCdeclFormat

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop r8
    pop r9

    ret

myPrintfFunctionCdeclFormat:
    push rbp
    mov rbp, rsp
    add rbp, 8
    mov rdi, 1
    mov rsi, [rbp + 8 * rdi]
    inc rdi ; current argument index

    ; mov rax, 0x01 ; syscall index of standard output function
    ; mov rdi, 1
    ; syscall

    ; pop rbp
    ; ret

    formatStringCharsLoop:
        ; ASK: how to fix this?
        cmp rdi, 7
        jne notArgumentGap ; skip argument gap
            inc rdi
        notArgumentGap:

        xor eax, eax
        lodsb
        cmp al, 0
        je formatStringLoopEnd ; c string is terminated with \0

        cmp al, FORMAT_STRING_DELIM
        je validFormatDelimeter
            push rsi
            call printSingleChar
            pop rsi
            jmp validFormatDelimIfEnd
        validFormatDelimeter:
            xor rax, rax
            lodsb ; read another symbol
            mov bl, al

            mov rax, [rbp + 8 * rdi]
            inc rdi

            push rsi
            ; switch on format type
            cmp bl, FORMAT_STRING_DELIM
            je percentCase
            cmp bl, HEX_FORMAT_STRING
            je hexademicalBaseCase
            cmp bl, OCTAL_FORMAT_STRING
            je octalBaseCase
            cmp bl, DECIMAL_FORMAT_STRING
            je decimalBaseCase
            cmp bl, BOOL_FORMAT_STRING
            je booleanTypeCase
            cmp bl, CHAR_FORMAT_STRING
            je charTypeCase
            cmp bl, STRING_FORMAT_STRING
            je stringTypeCase

            percentCase:
                dec rdi
                mov al, '%'
                call printSingleChar
                jmp switchCaseEnd
            hexademicalBaseCase:
                mov rbx, 16
                call printNumberInSomeBase
                jmp switchCaseEnd
            octalBaseCase:
                mov rbx, 8
                call printNumberInSomeBase
                jmp switchCaseEnd
            decimalBaseCase:
                mov rbx, 10
                call printNumberInSomeBase
                jmp switchCaseEnd
            booleanTypeCase:
                call printBoolean
                jmp switchCaseEnd
            charTypeCase:
                ; mov al, '?'
                call printSingleChar
                jmp switchCaseEnd
            stringTypeCase:
                call printString
                jmp switchCaseEnd
            switchCaseEnd:

            pop rsi
        validFormatDelimIfEnd:

        jmp formatStringCharsLoop
    formatStringLoopEnd:

    ; TODO:
    ; call clearAndOutputBuffer

    pop rbp
    ret

