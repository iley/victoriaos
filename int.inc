; VictoriaOS: intterrupt functions (division by zero, reboot)
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

;================================================
; #proc kernel initialization function
init_int:
    push    ax dx es

    push    cs
    pop     es

    ;set int0 (divisoin by zero) handler
   mov     dx, int_div_zero
   mov     al, 0
   call    set_vect

    ;set int51h (terminate) handler
    mov     al, 51h
    mov     dx, terminate_handler
    call    set_vect

	;terminate program on Alt-PrintScr
    mov     al, 05h
    mov     dx, terminate_handler
    call    set_vect

    ;set int52h (tsr) handler
    mov     al, 52h
    mov     dx, tsr_handler
    call    set_vect

;   mov     al, 19h
;   mov     dx, int_reboot
;   call    set_vect

    pop     es dx ax
    ret

;================================================
; #proc get interrupt vector
; #input: al - number of the interrupt vector
; #output: es:dx - address
get_vect:
    push    ax si ds
    push    0
    pop     ds
    xor     ah, ah
    shl     ax, 1
    shl     ax, 1   ;ax *= 4
    mov     si, ax
    mov     dx, [cs:si]
    add     si, 2
    mov     ax, [cs:si]
    mov     es, ax
    pop     ds si ax
    ret 

;================================================
; #proc set interrupt vector
; #input: al - number of the interrupt vector, es:dx - address
set_vect:
    push    ax di es
    cli
    cld
    xor     ah, ah
    mov     di, ax
    shl     di, 1
    shl     di, 1 ; di = al * 4

    push    es
    
    push    0
    pop     es
    
    mov     [es:di], dx

    inc     di
    inc     di    ;di = al * 4 + 2
    
    pop     ax
   
    stosw
    sti
    pop     es di ax
    ret

;================================================
; #proc devision by zero handler (debug version)

div_zero_msg db 13, 'Divizion by zero!!!', 13, 0
int_div_zero:
    push    cs
    pop     ds
    mov     dx, div_zero_msg
    call    puts
	jmp		terminate_handler

;================================================
; #proc reboot handler
msg_reboot db "Press any key to reboot...", 0
int_reboot:
    push    ax dx ds
    push    cs
    pop     ds
    mov     dx, msg_reboot
    call    puts
    call    getc
    pop     ds dx ax
    iret

