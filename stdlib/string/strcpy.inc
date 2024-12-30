; VictoriaOS: strcpy function

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
