; VictoriaOS: strcpy function
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

;================================================
; #proc string copy
; #input: ds:si - source, es:di - destination
strcpy:
    push    ax si di
    cld 
  strcpy_loop:
    lodsb
    stosb
    test    al, al
    jz      strcpy_exit
    jmp     strcpy_loop
  strcpy_exit:
    pop     di si ax
    ret
;-- vim: set filetype=fasm:
