; VictoriaOS: strcpy function
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

;================================================
; #proc string copy
; #input: ds:si - source, es:di - destination, cx - dest. buffer size
strncpy:
    push    ax cx si di
    dec     cx
    cld 
  strncpy_loop:
    lodsb
    stosb
    test    al, al
    jz      strncpy_exit
    loop    strncpy_loop
    xor     al, al  ;add \0 at the end
    stosb
  strncpy_exit:
    pop     di si cx ax
    ret
;-- vim: set filetype=fasm:
