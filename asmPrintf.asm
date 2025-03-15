global myPrintfFunction

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

    tmpStringBuff               db MAX_TMP_BUFF_LEN dup(0)
    formatStringBuff            db MAX_FORMAT_STR_BUFF_LEN dup(0)
    errorMessage                db "Some error has occured(", 10
    errorMessageLen             equ 24
    newLine                     db 10
    trueString                  db "true"
    trueStringLen               equ 4
    falseString                 db "false"
    falseStringLen              equ 5






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
    push rdi
    mov rax, 0x01 ; syscall index of standard output function
    mov rdi, 1    ; file descriptor for stdout

    syscall
    pop rdi
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

; entry: RBX base
;        RAX number
printNumberInSomeBase:
    push rcx
    push rdx
    push rax
    push rdi

    mov rdi, tmpStringBuff
    xor rcx, rcx

    digitLoop:
        xor rdx, rdx
        div rbx ; reminder to edx
        push rax
        mov rax, rdx

        cmp rax, 10
        jl reminderIsDigit
            add rax, 'A' - 10
            jmp reminderIsDigitIfEnd
        reminderIsDigit:
            add rax, '0'
        reminderIsDigitIfEnd:
        stosb
        pop rax

        inc rcx
        cmp rax, 0
        jne digitLoop

    mov rdx, rcx
    mov rsi, tmpStringBuff
    call myPrint

    pop rdi
    pop rax
    pop rdx
    pop rcx
    ret

; ENTRY: al - char to print
printSingleChar:
    push rdi
    mov rdi, tmpStringBuff
    stosb
    mov rsi, tmpStringBuff
    mov rdx, 1
    call myPrint
    pop rdi
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
    call myPrint

    pop rdi
    pop rsi
    ret

; ENTRY: rax - variable
printBoolean:
    push rsi
    push rdx

    cmp rax, 1
    je valIsTrue
        mov rdx, falseStringLen
        mov rsi, falseString
        call myPrint
        jmp valIsTrueIfEnd
    valIsTrue:
        mov rdx, trueStringLen
        mov rsi, trueString
        call myPrint
    valIsTrueIfEnd:

    pop rdx
    pop rsi
    ret

; System V calling convention (first 6 args are passed through registers and remaining are put to the stack)
myPrintfFunction:
    ; For now function only accepts arguments of INTEGER types (addresses, chars, ints)
    ; each argument is rounded up to 8 bytes
    ; arguments are put to registers in that order: RDI, RSI, RDX, RCX, R8, R9
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

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

    pop rbp
    ret

