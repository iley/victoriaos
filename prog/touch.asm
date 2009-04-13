; VictoriaOS: touch program
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

org 100h
include 'victoria.inc'

    jmp     start

    msg_error       db 'ERROR: Not enough command line parameters', 13, 0

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
    ;si is a start of the file name
    mov     dx, si

    syscall SC_FILE_EXISTS
    test    ax, ax
    jz      file_not_exist
    ret
file_not_exist:
    mov     al, O_WRITE
    syscall SC_OPEN_FILE
    syscall SC_CLOSE_FILE
    ret
