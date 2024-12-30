; VictoriaOS: program for displaying current system's version

org 100h

    jmp     start

include 'victoria.inc'

start:
    mov     dx, buffer
    syscall SC_GET_VER
    syscall SC_PUTS
    mov     al, 13
    syscall SC_PUTC
    ret
buffer:
;-- vim: set filetype=fasm:
