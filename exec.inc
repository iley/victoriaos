; VictoriaOS: program execution module
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

;PSP is a Program Segment Prefix
PSP_ERR_MODE    equ  002h   ;4 is sizeof.term_instr
PSP_CMD_LINE    equ  080h
PSP_CODE_START  equ  100h

term_instr:
    int     51h
    sizeof.term_instr= $ - term_instr

;================================================
; #proc execute program
; #input: ds:dx - program file name, ds:cx - command line
start_addr dw PSP_CODE_START, ?
exec:
    pusha
    push    ds es

    mov     si, cx  ;save cx for strcpy

    ;open file for reading
    mov     al, O_READ
    call    open_file

    ;allocate segment for the program
    call    malloc

    ;copy command line into PSP
    mov     di, PSP_CMD_LINE
    call    strcpy

    mov     word[es:PSP_ERR_MODE], DEF_ERR_MODE
    
    test    ax, ATTR_EXEC
    jnz     exec_can_run
    call    close_file
    call    free
    error   ERR_ACCESS_DENIED
  exec_can_run: 

    ;store terminate instructions at es:0000
    push    cx
    push    cs
    pop     ds
    mov     si, term_instr
    xor     di, di  ;mov di, 0000h
    mov     cx, sizeof.term_instr
    rep     movsb
    pop     cx
    
    ;read file
    push    es
    pop     ds
    mov     dx, PSP_CODE_START
    call    read    ;cx = file size after open_file

    call    close_file

    mov     ax, ss
    mov     cx, sp

    ;set stack for the program
    mov     bx, es
    mov     ss, bx
    mov     bx, 0fffeh  ;top of the stack
    mov     sp, bx

    ;new stack is used here
    push    es              ;save program segment for freeing
    push    cx              ;save SP
    push    ax              ;save SS
    push    0000h           ;this is for terminate by RET

    ;set DS for the program
    mov     ax, es
    mov     ds, ax

;   jmp     es:PSP_CODE_START
    mov     word[cs:start_addr+2], ax
    jmp     dword[cs:start_addr]

  exec_exit:
    ;restore default video mode if needed
    ;read current video mode
    mov     ah, 0fh
    int     10h

    cmp     al, DEF_VIDEO_MODE
    je      exec_right_video_mode
    mov     ah, 00h
    mov     al, DEF_VIDEO_MODE
    int     10h
  exec_right_video_mode:

    pop     es ds
    popa
    ret

;================================================
; terminate program handler (int 51h)
terminate_handler:
    mov     [cs:last_error], ERR_NONE
    jmp     terminate

;================================================
; tsr call handler (int 52h)
tsr_handler:
    mov     [cs:last_error], ERR_NONE
    jmp     tsr

;================================================
; terminate program
terminate:
    mov     ax, 0fff8h
    mov     sp, ax

    pop     ax
    pop     bx
    pop     es

    mov     ss, ax
    mov     sp, bx

    call    free

    jmp     exec_exit

;================================================
; terminate and stay resident (evil ;-)
; NOT TESTED
tsr:
    mov     ax, 0fff8h
    mov     sp, ax

    pop     ax
    pop     bx
    pop     es

    mov     ss, ax
    mov     sp, bx

    jmp     exec_exit
;-- vim: set filetype=fasm:
