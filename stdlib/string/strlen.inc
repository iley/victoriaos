; VictoriaOS: strlen function

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
