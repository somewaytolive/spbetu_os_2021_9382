LR2 SEGMENT
      ASSUME CS:LR2, DS:LR2, ES:NOTHING, SS:NOTHING
      ORG 100H ; PSP

START: JMP BEGIN

;DATA SEGMENT
    UN_MEM db 'Forbidden memory:', '$'
    ENV_ADDR db 'Environment address:', '$'
    COM_TAIL db 'Command tail:', '$'
    NO db 'no', '$'
    ENV_D db 'Environment data:' , '$'
    PATH db 'Path variables:' , '$'
    ENDL db 0dh, 0ah, '$'
;DATA ENDS

;CODE SEGMENT
PRINT_STR PROC near
    push AX
    mov ah, 09h
    int 21h
    pop AX
    ret
PRINT_STR ENDP

PRINT_LN PROC near
    call PRINT_STR
    mov DX, offset ENDL
    call PRINT_STR
    ret
PRINT_LN ENDP

PRINT_HEX_2B PROC
    push AX
    push BX
    mov BX, AX
    mov AL, AH
    call PRINT_HEX_1B
    mov AX, BX
    call PRINT_HEX_1B
    mov DX, offset ENDL
    call PRINT_STR
    pop BX
    pop AX
    ret
PRINT_HEX_2B ENDP

PRINT_HEX_1B PROC
    push AX
    push BX
    push DX
    mov AH, 0
    mov BL, 16
    div BL
    mov DX, AX
    mov AH, 02h
    cmp DL, 0Ah
        jl PRINT
    add DL, 7
    PRINT:
    add DL, '0'
    int 21h;
    mov DL, DH
    cmp DL, 0Ah
        jl PRINT2
    add DL, 7
    PRINT2:
    add DL, '0'
    int 21h;
    pop DX
    pop BX
    pop AX
    ret
PRINT_HEX_1B ENDP

PRINT_CHAR PROC
    push AX
    push DX
    xor DX, DX
    mov DL, AL
    mov AH, 02h
    int 21h
    pop DX
    pop AX
    ret
PRINT_CHAR ENDP

TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07
    NEXT:
    add AL,30h
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
    push CX ; байт в AL переводится в два символа шестн. числа в AX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX ; в AL старшая цифра
    pop CX ; в AH младшая
    ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near ; 16 с/с 16 bit. В AX - число, DI – адрес последнего символа
    push BX
    mov BH,AH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    dec DI
    mov AL,BH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    pop BX
    ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC near ; 10 с/с, SI - адрес поля младшей цифры
    push CX
    push DX
    xor AH,AH
    xor DX,DX
    mov CX,10
    loop_bd:
    div CX
    or DL,30h
    mov [SI],DL
    dec SI
    xor DX,DX
    cmp AX,10
    jae loop_bd
    cmp AL,00h
    je end_l
    or AL,30h
    mov [SI],AL
    end_l:
    pop DX
    pop CX
    ret
BYTE_TO_DEC ENDP

BEGIN:
    push DS
    sub AX,AX
    push AX
    ; Начало
    ; Память
    mov DX, offset UN_MEM
    call PRINT_STR
    mov AX, DS:[2h]
    call PRINT_HEX_2B


    ; Адрес
    mov DX, offset ENV_ADDR
    call PRINT_STR
    mov AX, DS:[2Ch]
    call PRINT_HEX_2B

    ; Хвост
    mov dx, offset COM_TAIL
    call PRINT_STR

    mov bx, 80h
    mov ch, 0
    mov cl, [bx]
    cmp cx, 0
        je TAIL_END
    mov bx, 81h
    mov ah, 02h

TAIL_FOR:
    mov dl, [bx]
    int 21h
    add bx, 1
    loop TAIL_FOR

    TAIL_END:
    mov dx, offset ENDL
    call PRINT_STR

    ; Окружение
    mov DX, offset ENV_D
    call PRINT_LN
    
    mov SI, 0
    mov BX, 2Ch
    mov ES, [BX]
START_ENV:
    cmp BYTE PTR ES:[SI], 0h
    je NEW_LINE
    mov AL, ES:[SI]
    call PRINT_CHAR
        jmp CHECK_END

NEW_LINE:
    mov DX, offset ENDL
    call PRINT_STR
CHECK_END:
    inc SI
    cmp WORD PTR ES:[SI], 0001h
        je WRITE_PATH
    jmp START_ENV

WRITE_PATH:
    mov DX, offset PATH
    call PRINT_STR
    add SI, 2
OUTPUT_PATH_FOR:
    cmp BYTE PTR ES:[SI], 00h
    je END_ENV_D
    mov AL, ES:[SI]
    call PRINT_CHAR
    inc SI
    jmp OUTPUT_PATH_FOR

    END_ENV_D:

    ; Выход
    xor AL,AL
    mov AH,4Ch
    int 21H
    ret

LR2 ENDS
      END START


