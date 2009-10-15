; VictoriaOS: file printing program
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

org 100h
include 'victoria.inc'
jmp     start

msg_error db 'ERROR: Not enough command line parameters', 13, 0

error:
    mov     dx, msg_error
    syscall SC_PUTS
    ret

start:
    mov     si, 0080h
    cld
scan_loop:
    lodsb
    test    al, al
    jz      error
    cmp     al, ' '
    jz      scan_found
    jmp     scan_loop
scan_found:
    ;si is a start of the file name
    mov     dx, si

    mov     al, O_READ
    syscall SC_OPEN_FILE
    
    mov     dx, buffer
    syscall SC_READ

    syscall SC_CLOSE_FILE

    test    cx, cx
    jz      print_end
    mov     si, buffer
print_loop:
    lodsb
    syscall SC_PUTC
    loop    print_loop
print_end:

    mov     al, 13
    syscall SC_PUTC

    ret
buffer:
;-- vim: set filetype=fasm:
