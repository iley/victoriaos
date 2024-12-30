; VictoriaOS: "Hello World" program

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
;-- vim: set filetype=fasm:
