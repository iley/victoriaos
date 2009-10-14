; VictoriaOS: stdcmp function
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

;================================================
; #proc string compare
; #input: ds:si - first, es:di - second
; #output: flags
strcmp:
    push    ax si di
    cld
  strcmp_loop:
    lodsb
    scasb
    jnz     strcmp_exit
    test    al, al
    jz      strcmp_exit
    jmp     strcmp_loop
  strcmp_exit:
    pop     di si ax
    ret
;-- vim: set filetype=fasm:
