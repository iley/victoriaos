; VictoriaOS: clear screen program
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

org 100h
include 'victoria.inc'

    mov     al, EOLN
    mov     cx, 2*SCR_HEIGHT
  loop0:
    syscall SC_PUTC
    loop    loop0
    ret
