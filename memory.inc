; VictoriaOS: memory control module
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

; bit array for the memory management
mem_table   dw 07fffh

;================================================
; #proc allocate segment
; #output: es - segment
malloc:
    push    ax bx cx
    pushf

    mov     bx, FIRST_SEG
    xor     ax, ax
    inc     ax
    mov     cx, SEG_NUM
  malloc_loop:
    test    [cs:mem_table], ax
    jnz     malloc_exit_loop
    add     bx, 1000h
    shl     ax, 1
    loop    malloc_loop
  malloc_exit_loop:
    
    test    cx, cx
    jnz     malloc_no_error
    error   ERR_MALLOC
  malloc_no_error:

    not     ax
    and     [cs:mem_table], ax

    mov     es, bx

    popf
    pop     cx bx ax
    ret

;================================================
; #proc free segment
; #input: es - segment
free:
    push    ax cx

    mov     cx, es

    cmp     cx, FIRST_SEG
    jb      free_err
    cmp     cx, LAST_SEG
    ja      free_err

    sub     cx, FIRST_SEG

	shr		cx, 12
    xor     ax, ax
    inc     ax
	test	cx, cx
	jz		free_skip_shl
	shl		ax, cl
  free_skip_shl:
    or      [cs:mem_table], ax
    jmp     free_exit
  free_err:
    error   ERR_FREE
  free_exit:
    pop     cx ax
    ret

;-- vim: set filetype=fasm:
