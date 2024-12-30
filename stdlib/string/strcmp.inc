; VictoriaOS: stdcmp function

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
