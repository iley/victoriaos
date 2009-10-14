; VictoriaOS: strlen function
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

;================================================
; #proc string length
; #input: ds:si - string
; #output: cx - length
strlen:
    push    ax si
    cld
    xor     cx, cx
  strlen_loop:
    lodsb
    test    al, al
    jz      strlen_exit
    inc     cx
    jmp     strlen_loop
  strlen_exit:
    pop     si ax
    ret
;-- vim: set filetype=fasm:
