; VictoriaOS: chmod program
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

org 100h
include 'victoria.inc'

    jmp     start
    msg_error           db 'ERROR: Not enough command line parameters', EOLN, 0
    msg_invalid_attr    db 'ERROR: Wrong attribute', EOLN, 0

    attr    dw 0

error:
    mov     dx, msg_error
    syscall SC_PUTS
    ret

start:
    mov     si, 0080h
    cld

scan_loop0:
    lodsb
    test    al, al
    jz      error
    cmp     al, ' '
    jz      scan_found0
    jmp     scan_loop0
scan_found0:
    ;si is a start of the mode string
    mov     di, si
    
    inc     si
scan_attr_loop:
    lodsb
    cmp     al, ' '
    je      scan_attr_loop_exit
    
    cmp     al, 'r'
    jne     skip_r
    or      word[attr], ATTR_READ
    jmp     scan_attr_loop
  skip_r:
    
    cmp     al, 'w'
    jne     skip_w
    or      word[attr], ATTR_WRITE
    jmp     scan_attr_loop
  skip_w:

    cmp     al, 'x'
    jne     skip_x
    or      word[attr], ATTR_EXEC
    jmp     scan_attr_loop
  skip_x:

    mov     dx, msg_invalid_attr
    syscall SC_PUTS
    syscall SC_TERMINATE
    jmp     scan_attr_loop
scan_attr_loop_exit:
    
;find file name
    mov     si, di
scan_loop1:
    lodsb
    test    al, al
    jz      error
    cmp     al, ' '
    jz      scan_found1
    jmp     scan_loop1
scan_found1:
    mov     byte[si-1], 0
    ;si is a start of the file name
    mov     dx, si

    ;dx is start of the file name
    syscall SC_GET_ATTR

    ; check for the '+' or '-' character
    cmp     byte[di], '+'
    jne     skip_add_attr
    or      ax, [attr]
    jmp     set_attr
  skip_add_attr:
    
    cmp     byte[di], '-'
    jne     skip_del_attr
    not     word[attr]
    and     ax, [attr]
    jmp     set_attr
  skip_del_attr:
    
    mov     dx, msg_invalid_attr
    syscall SC_PUTS
    syscall SC_TERMINATE

  set_attr:
    ;dx is file name, ax is attribute
    mov     cx, ax
    syscall SC_SET_ATTR
    
    ret
;-- vim: set filetype=fasm:
