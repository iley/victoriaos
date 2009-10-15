; VictoriaOS: program for displaying current system's version
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

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
