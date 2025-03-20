global myPrintfFunction

extern printf
extern atexit

MAX_FORMAT_STR_BUFF_LEN          equ 100
MAX_TMP_BUFF_LEN                 equ 100
ERROR_EXIT_CODE                  equ 228
FORMAT_STRING_DELIM              equ '%'
TRUE_STRING_LEN                  equ 4
FALSE_STRING_LEN                 equ 5
MAX_OUTPUT_BUFFER_LEN            equ 10
MAX_ARG_STRING_LEN               equ -1
SYSCALL_EXIT_FUNC_IND            equ 0x3C
SYSCALL_STANDART_OUTPUT_FUNC_IND equ 0x01
STDOUT_FILE_DESCR_ID             equ 1
MAX_NUMBER_STR_REPR_LEN          equ 64

; read only data
section .rodata
    hexDigitsString              db "0123456789ABCDEF"
    ;const equ formatsCharSwitchEnd-formatsCharSwitchTable
    %define JMP_TB_START formatsCharSwitchTable
    formatsCharSwitchTable:
        dd binaryBaseCase-JMP_TB_START,
        dd charTypeCase-JMP_TB_START,
        dd decimalBaseCase-JMP_TB_START,
        dd 'o'-'d'-1 dup(formatsCharSwitchEnd-JMP_TB_START),
        dd octalBaseCase-JMP_TB_START,
        dd 's'-'o'-1 dup(formatsCharSwitchEnd-JMP_TB_START),
        dd stringTypeCase-JMP_TB_START,
        dd 'x'-'s'-1 dup(formatsCharSwitchEnd-JMP_TB_START),
        dd hexademicalBaseCase-JMP_TB_START

; read and write access to data
section .data
    isMyPrintfFunctionLoaded         db 0
    outputBufferString               db MAX_OUTPUT_BUFFER_LEN dup(0)
    numOfCharsInOutputBuffer         dq 0 ; quad word






section .text

; entry: RSI - address of entry string
;        RDX - string len
; exit : none
; destr: RAX, RDI, non calee save registers that are destroyed in syscall
printGivenString:
    mov rax, SYSCALL_STANDART_OUTPUT_FUNC_IND ; syscall index of standard output function
    push r11
    mov rdi, STDOUT_FILE_DESCR_ID    ; file descriptor for stdout
    syscall
    pop r11
    ret

; flushes buffer, sets it's len = 0 (R11 = 0)
; entry: RDX - string len
;        R11 - number of chars in buffer
; exit : none
; destr: R11, RDX + destr in printGivenString
clearAndOutputBuffer:
    mov rdx, r11
    xor r11, r11 ; r11 = 0, num of chars in buffer = 0

    mov rsi, outputBufferString
    call printGivenString

    ret

;
; entry: AL  - char to add
;        R11 - number of chars in output buffer
; exit :
; destr: RAX, RBX, R11, RDI
addChar2Buffer:
    push rcx

    xor rbx, rbx
    mov rdi, outputBufferString
    add rdi, r11
    stosb
    inc r11

    cmp r11, MAX_OUTPUT_BUFFER_LEN
    jne notYetTimeToFlush
        call clearAndOutputBuffer
    notYetTimeToFlush:

    pop rcx
    ret

; prints number representation in some base (which is power of 2) to a buffer
; entry: BL - base shift (which power of 2)
;        BH - mask (to take bitwise mod)
;        RAX number
; exit : none
; destr: RAX, RCX, RDX
printNumberInBaseOfPower2:
    ; allocate memory for local buffer in stack
    enter MAX_NUMBER_STR_REPR_LEN, 0

    xor rcx, rcx
    digitLoopPower2Func:
        mov rdx, rax
        and dl, bh
        movsx rdx, dl
        mov dl, [hexDigitsString + rdx]

        dec rbp
        mov [rbp], byte dl

        mov rdx, rcx ; save loop counter
        mov cl, bl
        shr rax, cl  ; divide by base (/= 2 ^ shift same as >>= shift)
        mov rcx, rdx ; restore loop counter

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

; prints decimal representation of a number to an output buffer
; entry: RAX number
; exit : none
; destr: RAX, RBX, RCX, RDX + destr in addChar2Buff
printNumberInDecimalBase:
    ; allocate memory for local buffer in stack
    enter MAX_NUMBER_STR_REPR_LEN, 0

    xor rcx, rcx
    mov rbx, 10 ; decimal base is 10
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

; considers that there's enough space for a string in the buffer
; entry: RSI - string memory address
;        RDX - string len
;        R11 - number of chars in buffer
; exit : none
; destr: RAX, RCX, RSI, RDI, R11
addString2Buffer:
    mov rdi, outputBufferString
    add rdi, r11
    add r11, rdx
    mov rcx, rdx
    rep movsb

    jmp wholeStringInBufferIfEnd

; entry: RAX - address of a string
;        R11 - number of chars in buffer
; exit : none
; destr: RAX, RBX, RCX, RDX, RSI, RDI
printString:
    ; find string len
    push rax ; save string address
    xor rdx, rdx ; rdx = 0
    sub rdx, rax ; prepare string len reg

    mov rdi, rax ; load string address
    mov rcx, MAX_ARG_STRING_LEN ; max string len
    mov al, 0
    repne scasb ; search for terminating char
    add rdx, rdi ; RDX stores arg string len
    dec rdx

    pop rsi ; restore string address
    mov rbx, MAX_OUTPUT_BUFFER_LEN
    sub rbx, r11 ; calculate left space in buffer

    ; 3 cases (based on left space in output buffer and string len):
    ; 1) if there's enough space for a string in the buffer, we just add it to the buffer
    ; 2) there's not enough space for a string in the buffer, but it still can fit in it,
    ;    so first, we flush the buffer and then add string to it
    ; 3) string is too long, to fit even in empty buffer, so we just straight ahead output it

    ; RDX stores arg string len
    ; RBX stores left space in buffer
    cmp rbx, rdx
    jg wholeStringInBuffer
        push rdx
        push rsi
        call clearAndOutputBuffer
        pop rsi
        pop rdx

        cmp rdx, MAX_OUTPUT_BUFFER_LEN
        jge outputWholeStringAtOnce
            jmp addString2Buffer ; after func immediately jumps to wholeStringInBufferIfEnd
        outputWholeStringAtOnce:
            call printGivenString
            jmp wholeStringInBufferIfEnd
    wholeStringInBuffer:
        ; store whole string into the buffer
        jmp addString2Buffer ; after func immediately jumps to wholeStringInBufferIfEnd
    wholeStringInBufferIfEnd:

    jmp formatsCharSwitchEnd

; load function, sets it to be called during atexit func
; this way buffer is cleared
; we need to call this function only once, first time when our printf func is called
; Entry: none
; Exit : none
; Destr: RDI and some registers that are destructed by atexit (which ???)
loadMyPrintfFunction:
    ; calling C function atexit, to set handler that will be called at the end of C programm
    ; WARNING: stack address (rsp) should be divisble by 16
    mov rdi, clearAndOutputBuffer
    push r10
    ;sub rsp, 8
    call atexit ; attribute destructor attribute
    ;add rsp, 8
    pop r10

    mov [numOfCharsInOutputBuffer], dword 0

    jmp loadMyPrintfFunctionEnd

; trampoline to main printf function, prepares arguments
; System V calling convention (first 6 args are passed through registers and remaining are put to the stack)
myPrintfFunction:
    ; For now function only accepts arguments of INTEGER types (addresses, chars, ints)
    ; each argument is rounded up to 8 bytes
    ; arguments are put to registers in that order: RDI, RSI, RDX, RCX, R8, R9
    ; if there are more arguments, they are passed through stack in RTL (right to left order)
    ; so last argument is pushed first
    pop r10 ; save callback address

    ; push first 6 arguments to stack (in right to left order)
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    push r10

    cmp [isMyPrintfFunctionLoaded], byte 1
    je myFuncIsAlreadyLoaded
        jmp loadMyPrintfFunction
        loadMyPrintfFunctionEnd:
        mov [isMyPrintfFunctionLoaded], byte 1
    myFuncIsAlreadyLoaded:

    mov r11, [numOfCharsInOutputBuffer]
    ; ASK: is it ok that I pop arguments that were given to me?
    jmp myPrintfFunctionCdeclFormat

; main printf function
; Entry: arguments are passed through stack
; Exit : none
myPrintfFunctionCdeclFormat:
    pop r10 ; save callback address
    pop rsi ; load format string (first argument of printf)

    formatStringCharsLoop:
        xor eax, eax
        lodsb
        cmp al, 0
        je formatStringLoopEnd ; c string is terminated with \0

        cmp al, FORMAT_STRING_DELIM
        je validFormatDelimeter
            push rsi
            call addChar2Buffer
            pop rsi
            jmp validFormatDelimIfEnd
        validFormatDelimeter:
            xor rax, rax
            lodsb ; read another symbol

            cmp rax, '%'
            je percentCase

            ;switch on format type
            lea rdx, [JMP_TB_START]
            movsxd rbx, dword [JMP_TB_START + rax * 4 - 4 * 'b']
            add rbx, rdx
            ; rel of label??

            pop rax ; get new func argument from stack
            push rsi
            jmp rbx ; TODO: add check for an invalid type specificator (< 'b' or > 's')

            percentCase:
                push rsi
                mov al, '%'
                call addChar2Buffer
                jmp formatsCharSwitchEnd
            hexademicalBaseCase:
                mov bx, 0f04h ; shift 4 (/=16) and mask = 2 ^ 4 - 1 = 15 = f (in hex)
                call printNumberInBaseOfPower2
                jmp formatsCharSwitchEnd
            octalBaseCase:
                mov bx, 703h ; shift 3 and mask = 2 ^ 3 - 1 = 7
                call printNumberInBaseOfPower2
                jmp formatsCharSwitchEnd
            binaryBaseCase:
                mov bx, 101h ; shift 1 and mask = 2 ^ 1 - 1 = 1
                call printNumberInBaseOfPower2
                jmp formatsCharSwitchEnd
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
                jmp formatsCharSwitchEnd
            charTypeCase:
                call addChar2Buffer
                jmp formatsCharSwitchEnd
            stringTypeCase:
                jmp printString
            formatsCharSwitchEnd:

            pop rsi
        validFormatDelimIfEnd:

        jmp formatStringCharsLoop
    formatStringLoopEnd:

    ; save buffer len to memory, so that on the next call it will be valid
    mov [numOfCharsInOutputBuffer], r11

    push r10
    ret

