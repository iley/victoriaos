; VictoriaOS: "Hello World" program
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

org 100h

include 'victoria.inc'

jmp     start
    msg db 'Hello, World!', 13, 0
    attr db ?
start:
    syscall SC_GET_TEXT_ATTR
    mov     [attr], al
    mov     al, 02h
    syscall SC_SET_TEXT_ATTR
    mov     dx, msg
    syscall SC_PUTS
    mov     al, [attr]
    syscall SC_SET_TEXT_ATTR
    syscall SC_TERMINATE
