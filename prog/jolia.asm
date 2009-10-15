; VictoriaOS: Jolia fractal drawing demo program
; Copyright Nickolay Kudasov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

org 100h
include 'victoria.inc'

    jmp     start
    VID_SEG     equ 0a000h
    
    SCR_HEIGHT  equ 200
    SCR_WIDTH   equ 320

    TIME_DELAY  equ 1

    KEY_LEFT    equ 75
    KEY_RIGHT   equ 77

    KEY_UP      equ 72
    KEY_DOWN    equ 80

    KEY_INC     equ 78
    KEY_DEC     equ 74
    KEY_PAUSE   equ 57

    KEY_NEXT    equ 73
    KEY_PREV    equ 81

    KEY_ESCAPE  equ  1
    
align 16
    radius2 dq   4.0
    magic_x dq   0.0
    magic_y dq   0.0

    user_step   dq  0.05
    rad_step    dq  0.1
    magic_step  dq  0.1
    magic_angle dq  0.0
    magic_rad   dq  1.0

    left    dq  -2.0
    right   dq   2.0
    top     dq  -2.0
    bottom  dq   2.0

    time_hi dw  ?
    time_lo dw  ?

    height  dw  SCR_HEIGHT + 1
    width   dw  SCR_WIDTH  + 1
    curr    dw     ?

    color_shift db  0
    state       db  0

    start_msg   db  'Welcome to MAGIC JOLIA!', 13
                db  'Program was written by FIZRUK.', 13
                db  'Controls:', 13
                db  '    Increase Speed   -  UP', 13
                db  '    Decrease Speed   -  DOWN', 13
                db  '    Pause/Continue   -  SPACE', 13
                db  '    Next Frame       -  PAGEUP', 13
                db  '    Previous Frame   -  PAGEDOWN', 13
                db  '    Increase Palette -  RIGHT', 13
                db  '    Decrease Palette -  LEFT', 13
                db  '    Exit             -  ESCAPE', 13
                db  'Press any key to start MAGIC JOLIA...', 13
                db  0
    old_mode    db  ?

start:
    mov     dx, start_msg
    syscall SC_PUTS

    mov     ah, 0h
    int     16h

    mov     ah, 0fh
    int     10h
    mov     [old_mode], al

    ;ahksdgjkhdg
    mov     ax, 0013h
    int     10h

    push    VID_SEG
    pop     es

    finit

main_loop:

    cmp     byte [state], 0
    jnz     skip_recount

    call    recount
  
  skip_recount:     
    mov     ah, 1
    int     16h
    jz      main_loop

    mov     ah, 00h
    int     16h
    
    cmp     ah, KEY_PAUSE   
    jnz     skip_pause
    not     byte [state]
  skip_pause:

    cmp     ah, KEY_RIGHT
    jnz     skip_right
    inc     byte [color_shift]
    call    draw
  skip_right:

    cmp     ah, KEY_LEFT
    jnz     skip_left
    dec     byte [color_shift]
    call    draw
  skip_left:

    cmp     ah, KEY_UP
    jnz     skip_up
    fld     qword [magic_step]
    fld     qword [user_step]
    faddp
    fstp    qword [magic_step]
  skip_up:

    cmp     ah, KEY_DOWN
    jnz     skip_down
    fld     qword [magic_step]
    fld     qword [user_step]
    fsubp
    fstp    qword [magic_step]
  skip_down:

    cmp     ah, KEY_INC
    jnz     skip_inc
    fld     qword [magic_rad]
    fld     qword [rad_step]
    faddp
    fstp    qword [magic_rad]
    
    cmp     byte [state], 0
    jz      skip_inc
    push    word [magic_step] word [magic_step+2] word [magic_step+4] word [magic_step+6] 
    fldz
    fstp    qword [magic_step]
    call    recount
    pop     word [magic_step+6] word [magic_step+4] word [magic_step+2] word [magic_step]
  skip_inc:
    
    cmp     ah, KEY_DEC
    jnz     skip_dec
    fld     qword [magic_rad]
    fld     qword [rad_step]
    fsubp
    fstp    qword [magic_rad]

    cmp     byte [state], 0
    jz      skip_dec
    ;; Красиво, не правда ли? =)
    push    word [magic_step] word [magic_step+2] word [magic_step+4] word [magic_step+6] 
    fldz
    fstp    qword [magic_step]
    call    recount
    pop     word [magic_step+6] word [magic_step+4] word [magic_step+2] word [magic_step]
  skip_dec:

    cmp     ah, KEY_NEXT
    jnz     skip_next
    call    recount
  skip_next:

    cmp     ah, KEY_PREV
    jnz     skip_prev
    fld     qword [magic_step]
    fchs
    fstp    qword [magic_step]
    call    recount
    fld     qword [magic_step]
    fchs
    fstp    qword [magic_step]
  skip_prev:
    
    cmp     ah, KEY_ESCAPE
    jnz     main_loop
        
exit:
    mov     ah, 0h
    mov     al, [old_mode]
    int     10h
    ret

recount:
    push ax bx

    fld     qword [magic_angle]
    fld     qword [magic_step]
    faddp
    fldpi
    fadd    st0, st0
    fxch
    fprem
    fstp    qword [magic_angle]

    fld     qword [magic_angle]
    fld     st0
    fcos
    fld     qword [magic_rad]
    fmulp
    fstp    qword [magic_x]

    fsin
    fld     qword [magic_rad]
    fmulp
    fstp    qword [magic_y]

    mov     ah, 0h
    int     1ah

    call    draw

    mov     bx, TIME_DELAY
    call    wait_ticks

    pop     bx ax

    ret

wait_ticks:
    push    dx cx ax

    mov     [time_hi], cx
    mov     [time_lo], dx

wait_loop:
    mov     ah, 0h
    int     1ah

    sub     dx, [time_lo]
    sbb     cx, [time_hi]

    cmp     dx, bx
    jb      wait_loop

    pop     ax cx dx
    
    ret

draw:
    pusha

    xor     di, di
    mov     cx, SCR_HEIGHT

height_loop:

    mov     bx, SCR_WIDTH

width_loop:
    ; (right - left) * bx / SCR_WIDTH + left
    ;  right left - bx * SCR_WIDTH / left +
    fld     qword [right]
    fld     qword [left]
    fsubp

    mov     [curr], bx
    fild    word [curr]
    fmulp

    fild    word [width]
    fdivp

    fld     qword [left]
    faddp

    ; (bottom - top) * cx / SCR_HEIGHT + top
    ; bottom top - cx * SCR_HEIGHT / top +
    fld     qword [bottom]
    fld     qword [top]
    fsubp

    mov     [curr], cx
    fild    word [curr]
    fmulp

    fild    word [height]
    fdivp

    fld     qword [top]
    faddp

    ; st0 = Y_coord
    ; st1 = X_coord
    ; =================

    xor     dl, dl
  recount_coords:   
    inc     dl
    cmp     dl, 254
    ja      end_count

    ; x = x*x - y*y + c.x
    fld     st1
    fmul    st0, st0

    fld     st1
    fmul    st0, st0

    fsubp
    fld     qword [magic_x]
    faddp

    ; y = 2*x*y + c.y
    fld     st2
    fmul    st0, st2
    fadd    st0, st0

    fld     qword [magic_y]
    faddp

    fxch    st3
    fxch    st1
    fxch    st3

    fxch    st2

    fstp    st0
    fstp    st0
  
    ; x*x + y*y < radius2
    ; x x * y y * +

    fld     st1
    fmul    st0, st0

    fld     st1
    fmul    st0, st0

    faddp
    fld     qword [radius2]
    
    fcompp
    fstsw   ax
    sahf

    jae     recount_coords

  end_count:
    add     dl, [color_shift]
    mov     al, dl
    stosb

    fstp    st0
    fstp    st0

    dec     bx
    jnz     width_loop
    
    dec     cx
    jnz     height_loop

    popa

    ret
;-- vim: set filetype=fasm:
