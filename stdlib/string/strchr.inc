; VictoriaOS: strchr

;================================================
;#proc strchr
;#input SI - string, DL - character
;#output SI - adress of character, BX - error code
strchr:
    push    ax dx

    cld
  strchr_loop:
    lodsb
    test    al, al
    jz      strchr_exit_loop
    cmp     al, dl
    jnz     strchr_loop
  strchr_exit_loop:
    
    mov     bx, 1
    test    al, al
    jz      strchr_exit
    xor     bx, bx
    dec     si
  strchr_exit:

    pop     dx ax
    ret
;-- vim: set filetype=fasm:
