; VictoriaOS: clear screen program

org 100h
include 'victoria.inc'

    mov     al, EOLN
    mov     cx, 2*SCR_HEIGHT
  loop0:
    syscall SC_PUTC
    loop    loop0
    ret
;-- vim: set filetype=fasm:
