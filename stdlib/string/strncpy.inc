; VictoriaOS: strcpy function

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
