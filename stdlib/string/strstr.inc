; VictoriaOS: strstr function

;================================================
;#proc strstr
;#input DS:SI - first string, ES:DI - second string
;#output DS:SI - adress of string match, BX - error code
strstr:
    push    ax cx dx di es

    xchg    si, di
    call    strlen
    mov     bx, cx

    mov     ax, si
    mov     dx, di

    cld
  strstr_loop:
    mov     si, ax
    mov     di, dx
    inc     dx
    cmp     byte [di], 0
    jz      strstr_exit
    mov     cx, bx
    repe    cmpsb
    test    cx, cx
    jnz     strstr_loop

    dec     dx
    mov     si, dx

  strstr_exit:
    mov     bx, cx

    pop     es di dx cx ax
    ret
;-- vim: set filetype=fasm:
