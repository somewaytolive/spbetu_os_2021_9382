ASTACK	SEGMENT  STACK
	DW 100h DUP(?)			
ASTACK  ENDS

DATA SEGMENT

	FILENAME 	db 'LR2.COM', 0
	PARAM_BLOCK dw 0
				dd 0
				dd 0
				dd 0
	KEEP_SS 	dw 0
	KEEP_SP 	dw 0
	KEEP_PSP 	dw 0
	ERR7_MEM 	db 13,10,'Memory control block is destroyed',13, 10,'$'
	ERR8_MEM 	db 13,10,'Not enough memory for function',	 13, 10,'$'
	ERR9_MEM 	db 13,10,'Invalid adress',					 13, 10,'$'	
	
	ERR1_LOAD 	db 13,10,'Incorrect function number',		 13, 10,'$'
	ERR2_LOAD 	db 13,10,'File not found',					 13, 10,'$'
	ERR5_LOAD 	db 13,10,'Disk error', 						 13, 10,'$'
	ERR8_LOAD 	db 13,10,'Not enough memory',				 13, 10,'$'
	ERRA_LOAD 	db 13,10,'Invalid environment',				 13, 10,'$'
	ERRB_LOAD 	db 13,10,'Incorrect format',				 13, 10,'$'

	ERR0_ENDING db 13,10,'Normal completion$'
	ERR1_ENDING db 13,10,'Completion by Ctrl-Break$'
	ERR2_ENDING db 13,10,'Device error termination$'
	ERR3_ENDING db 13,10,'Completion by function 31h$'

	PATH 		db 50 dup (0),'$'
	COMPLETION 	db 13,10,'Program ended with code: $'
	DATA_END 	db 0
	
DATA  ENDS

CODE	SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:ASTACK
	
;--------------------------------------------------------------------------------
;print al in 16s/s
HEX_BYTE_PRINT PROC near
	push ax
	push bx
	push dx
	mov ah, 0
	mov bl, 10h
	div bl 
	mov dx, ax ; dl - первая цифра, dh - вторая
	mov ah, 2h
	cmp dl, 0ah 
	jl PRINT_1	;если в dl - цифра
	add dl, 7   ;сдвиг в ASCII с цифр до букв
PRINT_1:
	add dl, '0'
	int 21h
	mov dl, dh
	cmp dl, 0ah
	jl PRINT_2   
	add dl, 7	
PRINT_2:
	add dl, '0'
	int 21h
	pop dx
	pop bx
	pop ax
	ret
HEX_BYTE_PRINT ENDP
;--------------------------------------------------------------------------------
WriteMsg PROC near
	push ax
    mov ah,09h
    int 21h
	pop ax
    ret
WriteMsg ENDP
;--------------------------------------------------------------------------------
FREE_MEM PROC near
	push ax
	push bx
	push cx
	push dx 
		
	mov bx, offset _END
	mov ax, offset DATA_END
	add bx, ax
	add bx, 40Fh
	mov cl, 4
	shr bx, cl
	mov ah, 4Ah
	int 21h
	jnc	end_fm
		
	irpc var1, 789		;аналог range-based c++
		cmp ax, &var1&
		je ERRM_&var1&
	endm
		
	irpc var2, 789
		ERRM_&var2&:
		mov dx, offset ERR&var2&_MEM
		call WriteMsg
		mov ax, 4C00h
		int 21h
	endm
		
end_fm:	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FREE_MEM ENDP
;--------------------------------------------------------------------------------
PREPAIR_DATA proc near
	mov ax,KEEP_PSP
	mov es,ax
	
	push ax
	push es
	push si
	push di
	push dx
	
	mov es, es:[2Ch]
	mov si,0
	lea di, PATH
env_skip:
	mov dl, es:[si]
	cmp dl, 00			
	je env_end	
	inc si
	jmp env_skip
env_end:
	inc si
	mov dl, es:[si]
	cmp dl, 00	
	jne env_skip
	add si, 3	
write_path:
	mov dl, es:[si]
	cmp dl, 00	
	je write_name	
	mov [di], dl	
	inc si			
	inc di			
	jmp write_path
write_name:
	mov si,0
file_name:
	mov dl, byte ptr [FILENAME+si]
	mov byte ptr [di-7], dl
	inc di
	inc si
	test dl, dl
	jne file_name

	mov KEEP_SS, ss
	mov KEEP_SP, sp
	
	pop dx
	pop di
	pop si
	pop es
	pop ax
	ret
PREPAIR_DATA ENDP
;--------------------------------------------------------------------------------
LOAD proc near
	push ax
	push bx
	push dx 
	push ds
	push ss
	push sp
	
	push ds
	pop es
	
	mov bx, offset PARAM_BLOCK	
	mov dx, offset PATH
		
	mov ah, 4bh
	mov al, 0
	int 21h
		
	jnc no_err
	mov bx, DATA
	mov ds, bx
	mov ss, KEEP_SS
	mov sp, KEEP_SP

	irpc case, 1258AB
		cmp ax, 0&case&h
		je ERRL_&case&
	endm
		
	irpc met, 1258AB
		ERRL_&met&:
		mov dx, offset ERR&met&_LOAD
		call WriteMsg
		mov ax, 4C00h
		int 21h
	endm
		
no_err:
	mov ax, 4D00h 
	int 21h
		
	cmp al,3 ;код завершения при CTRL+C
	je ctrl_c
			
	irpc case, 0123
		cmp ah, &case&
		je ERRE_&case&
	endm
		
	irpc met, 0123
		ERRE_&met&:
		mov dx, offset ERR&met&_ENDING
		call WriteMsg
		jmp last_step
	endm
last_step:
	mov dx,0
	mov dx, offset COMPLETION
	call WriteMsg
	call HEX_BYTE_PRINT
	jmp __end		
ctrl_c:
	mov dx, offset ERR1_ENDING
	call WriteMsg			
__end:
	pop sp
	pop ss
	pop ds
	pop dx
	pop bx
	pop ax
	ret
LOAD ENDP

MAIN proc far
    mov ax, DATA
    mov ds, ax
	mov KEEP_PSP, ES
	call FREE_MEM
	call PREPAIR_DATA
	call LOAD
	mov ax, 4C00h
	int 21h
	ret
MAIN endp
_END:
CODE ENDS

end MAIN