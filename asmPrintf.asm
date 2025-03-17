global myPrintfFunction

extern printf
extern atexit

section .data
    MAX_FORMAT_STR_BUFF_LEN          equ 100
    MAX_TMP_BUFF_LEN                 equ 100
    DECIMAL_FORMAT_STRING            equ 'd'
    BOOL_FORMAT_STRING               equ 'b'
    OCTAL_FORMAT_STRING              equ 'o'
    HEX_FORMAT_STRING                equ 'x'
    CHAR_FORMAT_STRING               equ 'c'
    STRING_FORMAT_STRING             equ 's'
    FORMAT_STRING_DELIM              equ '%'
    ERROR_EXIT_CODE                  equ 228
    TRUE_STRING_LEN                  equ 4
    FALSE_STRING_LEN                 equ 5
    MAX_OUTPUT_BUFFER_LEN            equ 10
    MAX_ARG_STRING_LEN               equ 100
    SYSCALL_EXIT_FUNC_IND            equ 0x3C
    SYSCALL_STANDART_OUTPUT_FUNC_IND equ 0x01
    MAX_NUMBER_STR_REPR_LEN          equ 64


    tmpStringBuff                    db MAX_TMP_BUFF_LEN dup(0)
    formatStringBuff                 db MAX_FORMAT_STR_BUFF_LEN dup(0)
    ; errorMessage                     db "Some error has occured(", 10
    ; errorMessageLen                  equ 24
    newLine                          db 10
    trueString                       db "true", 0
    falseString                      db "false", 0

    outputBufferString               db MAX_OUTPUT_BUFFER_LEN dup(0)
    numOfCharsInOutputBuffer         dd 0 ; double word






section .text

exitProgrammWithError:
    mov eax, SYSCALL_EXIT_FUNC_IND
    mov ebx, ERROR_EXIT_CODE

    syscall
    ret ; ???

; entry: RSI - address of entry string
printGivenString:
    mov rax, SYSCALL_STANDART_OUTPUT_FUNC_IND ; syscall index of standard output function
    mov rdi, 1    ; file descriptor for stdout
    syscall
    ret

; entry: RDX - string len
;        RSI - address of source string
clearAndOutputBuffer:
    push rdi
    push rsi
    push rdx
    push rax

    mov rdx, [numOfCharsInOutputBuffer] ; len of buffer
    ; numOfCharsInOutputBuffer = 0
    mov word [numOfCharsInOutputBuffer], 0

    mov rsi, outputBufferString
    call printGivenString

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

    mov eax, [numOfCharsInOutputBuffer]
    inc eax
    mov dword [numOfCharsInOutputBuffer], eax

    cmp eax, MAX_OUTPUT_BUFFER_LEN
    jne notYetTimeToFlush
        call clearAndOutputBuffer
    notYetTimeToFlush:

    pop rcx ; ASK: what did change rcx?
    pop rbx
    pop rax
    pop rdi
    ret

; entry: BL - base shift (which power of 2)
;        BH - mask (to take bitwise mod)
;        RAX number
printNumberInBaseOfPower2:
    ; allocate memory for local buffer in stack
    enter MAX_NUMBER_STR_REPR_LEN, 0

    xor rcx, rcx
    digitLoopPower2Func:
        ; ASK: ?
        mov rdx, rax
        and dl, bh
        add dl, '0'
        cmp dl, '0' + 10
        jl decimalDigit ; in case if base is 16 and we can have a digit >= 10
            add dl, 'A' - '0' - 10
        decimalDigit:
        dec rbp
        mov [rbp], byte dl

        mov rdx, rcx
        xor cl, cl
        mov cl, bl
        shr rax, cl
        mov rcx, rdx

        inc rcx
        cmp rax, 0
        jne digitLoopPower2Func

    digitOutputLoopPower2Func:
        mov al, byte [rbp]
        inc rbp
        call addChar2Buffer
        loop digitOutputLoopPower2Func

    ; free allocated memory
    leave
    ret

; entry: RAX number
printNumberInDecimalBase:
    ; allocate memory for local buffer in stack
    enter MAX_NUMBER_STR_REPR_LEN, 0

    xor rcx, rcx
    mov rbx, 10
    digitLoop:
        xor rdx, rdx
        div rbx ; reminder to edx

        add dl, '0'
        dec rbp
        mov [rbp], byte dl

        inc rcx
        cmp rax, 0
        jne digitLoop

    digitOutputLoop:
        mov al, byte [rbp]
        inc rbp
        call addChar2Buffer
        loop digitOutputLoop

    ; free allocated memory
    leave
    ret

; entry: AL - char to print
printSingleChar:
    call addChar2Buffer
    ret

; considers that there's enough space for a string in the buffer
; entry: RSI - string memory address
;        RCX - string len
addString2Buffer:
    xor rax, rax
    mov eax, [numOfCharsInOutputBuffer]
    mov rdi, outputBufferString
    add rdi, rax
    add rax, rcx
    mov [numOfCharsInOutputBuffer], eax
    rep movsb

    ret

; entry: RAX - address of a string
printString:
    push rsi
    push rdi

    ; find string len
    push rax ; save string address
    xor rdx, rdx ; rdx = 0
    sub rdx, rax ; prepare string len reg

    mov rdi, rax ; load string address
    mov rcx, MAX_ARG_STRING_LEN ; max string len
    mov al, 0
    repne scasb ; search for terminating char
    add rdx, rdi

    pop rsi ; restore string address
    mov rbx, MAX_OUTPUT_BUFFER_LEN
    sub rbx, rcx ; calculate left space in buffer


    ; 3 cases (based on left space in output buffer and string len):
    ; 1) if there's enough space for a string in the buffer, we just add it to the buffer
    ; 2) there's not enough space for a string in the buffer, but it still can fit in it,
    ;    so first, we flush the buffer and then add string to it
    ; 3) string is too long, to fit even in empty buffer, so we just straight ahead output it
    cmp rbx, rcx
    jge wholeStringInBuffer
        cmp rcx, MAX_OUTPUT_BUFFER_LEN
        call clearAndOutputBuffer
        jge outputWholeStringAtOnce
            call addString2Buffer
            jmp outputWholeStringAtOnceIfEnd
        outputWholeStringAtOnce:
            call printGivenString
        outputWholeStringAtOnceIfEnd:
        jmp wholeStringInBufferIfEnd
    wholeStringInBuffer:
        ; store whole string into the buffer
        call addString2Buffer
    wholeStringInBufferIfEnd:

    pop rdi
    pop rsi
    ret

; System V calling convention (first 6 args are passed through registers and remaining are put to the stack)
myPrintfFunction:
    ; For now function only accepts arguments of INTEGER types (addresses, chars, ints)
    ; each argument is rounded up to 8 bytes
    ; arguments are put to registers in that order: RDI, RSI, RDX, RCX, R8, R9
    ; if there are more arguments, they are passed through stack in RTL (right to left order)
    ; so last argument is pushed first
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    ; calling C function atexit, to set handler that will be called at the end of C programm
    ; ASK: how does it work? what if my function overwrites smth important?
    sub rsp, 8
    mov rdi, clearAndOutputBuffer
    call atexit ; attribute destructor attribute
    add rsp, 8

    call myPrintfFunctionCdeclFormat

    ; TODO: переписать на трамплин
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
    mov rsi, [rbp + 8 * rdi] ; load format string (first argument of printf)
    inc rdi ; current argument index

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
            je binaryTypeCase
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
                mov bx, 0f4h
                mov bh, 15
                mov bl, 4
                call printNumberInBaseOfPower2
                jmp switchCaseEnd
            octalBaseCase:
                mov bx, 73h ; shift 3 and mask = 2 ^ 3 - 1 = 7
                mov bh, 7 ; ASK: why doesn't bx=... work?
                mov bl, 3
                call printNumberInBaseOfPower2
                jmp switchCaseEnd
            decimalBaseCase:
                cmp rax, 0
                jge positiveNumber ; in case if number is negative
                    push rax
                    mov al, '-'
                    call addChar2Buffer
                    pop rax
                    neg rax
                positiveNumber:

                mov rbx, 10
                call printNumberInDecimalBase
                jmp switchCaseEnd
            binaryTypeCase:
                mov bx, 00010001b ; shift 1 and mask = 2 ^ 1 - 1 = 1
                mov bh, 1
                mov bl, 1
                call printNumberInBaseOfPower2
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

    ; call clearAndOutputBuffer

    pop rbp
    ret

