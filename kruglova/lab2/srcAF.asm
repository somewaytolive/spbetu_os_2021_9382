SOURCE segment
    ASSUME cs: SOURCE, ds: SOURCE, es: NOTHING, ss: NOTHING
    org 100h

START: jmp PROGRAM

    AVAILABLE_MEMORY_STR    db  "--- Available memory (kilobytes): $"
    EXTENDED_MEMORY_STR     db  "--- Extended memory (kilobytes): $"
    
    FREE_EXCEPTION          db  "Free memory exception", 0Dh, 0Ah, "$"
    ALLOC_EXCEPTION         db  "Alloc memory exception", 0Dh, 0Ah, "$"

    TITLE_LINE       db '-----------------------MCB blocks-----------------------', 0Dh, 0Ah
    TITLE_LINE_2     db '| Address | Type | PSP Address | Size(kb) | Name       |', 0Dh, 0Ah, '$'
    MCB_LINE_ADDR    db '|         |'
    MCB_LINE_TYPE    db            '      |'
    MCB_LINE_PSP     db                   '             |'
    MCB_LINE_SIZE    db                                 '          |'
    MCB_LINE_NAME    db                                            '            |', 0Dh, 0Ah
    MCB_LINE_END     db '--------------------------------------------------------'
    ENDL             db  0Dh, 0Ah, "$"


PRINT_STRING_DX PROC near
    push AX
    mov ah, 09h
    int 21h
    pop AX
    ret
PRINT_STRING_DX ENDP

PRINT_DEC_AX PROC NEAR
    push ax
    push cx
    push dx
    push bx
    mov bx, 10
    xor cx, cx

    NUM_CALCULATE:
    div bx
    push dx
    xor dx, dx
    inc cx
    cmp ax, 0h
        jnz NUM_CALCULATE

    PRINT_NUM_LOOP:
    pop dx
    or dl, 30h
    mov ah, 02h
    int 21h
        loop PRINT_NUM_LOOP

    pop bx
    pop dx
    pop cx
    pop ax
    ret
PRINT_DEC_AX ENDP

PRINT_HEX_AL PROC NEAR
    push ax
    push bx
    push dx

    mov ah, 0
    mov bl, 10h
    div bl
    mov dx, ax
    mov ah, 02h
    cmp dl, 0Ah
        jl HEX_PRINT
    add dl, 07h

    HEX_PRINT:
    add dl, '0'
    int 21h;

    mov dl, dh
    cmp dl, 0Ah
        jl PRINT_EXT
    add dl, 07h

    PRINT_EXT:
    add dl, '0'
    int 21h;

    pop dx
    pop bx
    pop ax
    ret
PRINT_HEX_AL ENDP

PRINT_HEX_AX PROC NEAR
    push ax
    push ax
    mov al, ah
    call PRINT_HEX_AL
    pop ax
    call PRINT_HEX_AL
    pop ax
    ret
PRINT_HEX_AX ENDP

TETR_TO_HEX	PROC near
    and al, 0fh
    cmp al, 09
        jbe NEXT
    add al, 07

    NEXT:
    add al, 30h
    ret
TETR_TO_HEX	ENDP

BYTE_TO_HEX	PROC near
    push cx
    mov ah,al
    call TETR_TO_HEX
    xchg al, ah
    mov cl,4
    shr al, cl
    call TETR_TO_HEX 
    pop cx
    ret
BYTE_TO_HEX	ENDP

WORD_TO_HEX PROC near
    push bx
    mov bh,ah
    call BYTE_TO_HEX
    mov [di],ah
    dec di
    mov [di],al
    dec di
    mov al,bh
    xor ah,ah
    call BYTE_TO_HEX
    mov [di],ah
    dec di
    mov [di],al
    pop bx
    ret
WORD_TO_HEX ENDP

BYTE_TO_DEC	PROC near
    push cx
    push dx
    push ax
    xor ah,ah
    xor dx,dx
    mov cx,10

    loop_bd:
    div cx
    or dl,30h
    mov [si],dl
    dec si
    xor dx,dx
    cmp ax,10
    jae loop_bd
    cmp ax,00h
    jbe btd_endl
    or al,30h
    mov [si],al

    btd_endl:
    pop ax
    pop dx
    pop cx
    ret
BYTE_TO_DEC	ENDP

WORD_TO_DEC PROC NEAR
    push cx
    push dx
    mov cx,10

    loop_b:
    div cx
    or dl,30h
    mov [si],dl
    dec si
    xor dx,dx
    cmp ax,10
    jae loop_b
    cmp al,00h
    je wtd_endl
    or al,30h
    mov [si],al

    wtd_endl:
    pop dx
    pop cx
    ret
WORD_TO_DEC ENDP

TRY_FREE_MEMORY PROC NEAR
    push ax
    push bx
    push cx
    push dx

    FREE_TRY:
    mov bx, offset PROGRAMM_END
    mov cl, 4
    shr bx, cl
    add bx, 1
    mov ah, 4Ah
    int 21h
        jnc	FREE_FINALLY

    FREE_CATCH:
    mov dx, offset FREE_EXCEPTION
    call PRINT_STRING_DX

    FREE_FINALLY:
    pop dx
    pop	cx
    pop bx
    pop ax
    ret
TRY_FREE_MEMORY ENDP

TRY_ALLOC_MEMORY PROC NEAR
    push ax
    push bx
    push cx
    push dx

    ALLOC_TRY:
    mov bx, 1000h
    mov ah, 48h
    int 21h
    jnc ALLOC_FINALLY

    ALLOC_CATCH:
    mov dx, offset ALLOC_EXCEPTION
    call PRINT_STRING_DX

    ALLOC_FINALLY:
    pop dx
    pop	cx
    pop bx
    pop ax
    ret
TRY_ALLOC_MEMORY ENDP

AVAILABLE_MEMORY PROC NEAR
    push ax
    push bx
    push dx

    mov dx, offset AVAILABLE_MEMORY_STR
    call PRINT_STRING_DX

    xor ax, ax
    int 12h
    xor dx, dx
    call PRINT_DEC_AX

    mov dx, offset ENDL
    call PRINT_STRING_DX

    pop dx
    pop bx
    pop ax
    ret
AVAILABLE_MEMORY ENDP

EXTENDED_MEMORY PROC NEAR
    push ax
    push bx
    push dx

    mov dx, offset EXTENDED_MEMORY_STR
    call PRINT_STRING_DX

    mov al, 30h
    out 70h, al
    in 	al, 71h
    mov bl, al
    mov al, 31h
    out 70h, al
    in 	al, 71h
    mov ah, al
    mov al, bl
    xor dx, dx

    call PRINT_DEC_AX

    mov dx, offset ENDL
    call PRINT_STRING_DX

    pop dx
    pop bx
    pop ax
    ret
EXTENDED_MEMORY ENDP

MCB_PRINT PROC near
    push ax
    push bx
    push cx
    push dx
    push es
    push si

    sub ax, ax
    sub dx, dx
    lea dx, TITLE_LINE
    call PRINT_STRING_DX
    lea dx, MCB_LINE_END
    call PRINT_STRING_DX
    mov ah, 52h
    int 21h
    sub bx, 2h
    mov es, es:[bx]

    MCB_FOR_LOOP:
    lea di, MCB_LINE_TYPE
    add di, -4
    mov ax, es
    call WORD_TO_HEX
    
    lea di, MCB_LINE_PSP
    add di, -5
    sub ah, ah
    mov al, es:[0]
    call BYTE_TO_HEX
    mov [di], al
    inc di
    mov [di], ah

    lea di, MCB_LINE_SIZE
    add di, -6
    mov ax, es:[1]
    call WORD_TO_HEX

    lea di, MCB_LINE_NAME
    add di, -3
    mov ax, es:[3]
    mov bx, 10h
    mul bx
    push si
    mov si, di
    call WORD_TO_DEC
    pop si
    
    lea di, MCB_LINE_NAME
    add di, 1
    mov bx, 0
    LAST_8_BYTES:
    mov dl, es:[bx + 8]
    mov [di], dl
    inc di
    inc bx
    cmp bx, 8
        jne	LAST_8_BYTES
    mov ax, es:[3]
    mov bl, es:[0]
    
    lea dx, MCB_LINE_ADDR
    call PRINT_STRING_DX
    
    mov cx, es
    add ax, cx
    inc ax
    mov es, ax

    cmp bl, 4Dh
        je MCB_FOR_LOOP

    pop cx
    pop si
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret
MCB_PRINT ENDP


PROGRAM:
    call TRY_ALLOC_MEMORY
    call TRY_FREE_MEMORY
    
    call AVAILABLE_MEMORY
    call EXTENDED_MEMORY
    call MCB_PRINT

    xor al, al
    mov ah, 4Ch
    int 21h

PROGRAMM_END:

SOURCE ends
end START
