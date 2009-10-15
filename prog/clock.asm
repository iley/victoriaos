; VictoriaOS: resident clock
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

org 100h

include 'victoria.inc'

    jmp     start
    
    DELAY           equ 10
    TEXT_ATTR       equ 20h
    TEXT_ATTR_BLINK equ 80h
    VIDEO_SEG       equ 0b800h
    
    start_msg   db 'TSR clock installed', EOLN, 0
    is_started  db 0

    ticks       dw 0

tsr_proc:
    pusha
    push    ds es

    cmp     byte[is_started], 0
    jnz     tsr_proc_return

    inc     word[ticks]
    cmp     word[ticks], DELAY
    jb      tsr_proc_return

    mov     word[ticks], 0

    mov     byte[is_started], 1

    push    VIDEO_SEG
    pop     es
    mov     di, 150

    mov     ah, 02h
    int     1ah

    mov     ah, TEXT_ATTR

    mov     al, ch
    and     al, 0f0h
    shr     al, 4
    add     al, '0'
    stosw

    mov     al, ch
    and     al, 0fh
    add     al, '0'
    stosw

    or      ah, TEXT_ATTR_BLINK
    mov     al, ':'
    stosw

    mov     ah, TEXT_ATTR

    mov     al, cl
    and     al, 0f0h
    shr     al, 4
    add     al, '0'
    stosw

    mov     al, cl
    and     al, 0fh
    add     al, '0'
    stosw

    mov     byte[is_started], 0
  tsr_proc_return:
    pop     es ds
    popa
    iret

start:
    push    cs
    pop     es
    mov     dx, tsr_proc
    mov     al, 1ch
    syscall SC_SET_VECT

    mov     dx, start_msg
    syscall SC_PUTS

    int     52h
;-- vim: set filetype=fasm:
