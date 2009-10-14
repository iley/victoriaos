; VictoriaOS: loader
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

org 7c00h
include 'victoria.inc'

jmp start

    include 'const.inc'

    FAT_EOF equ 0ffffh
    vect    equ 50h * 4  

    shutdown_msg db 'Now you can turn off your computer or press any key to reboot!', 0

    logo_fname      db 'logo', 0
    autoexec_fname  db 'autoexec', 0

    shell_fname db 'shell', 0
    msg_welcome db 'Welcome to ', 0

run_autoexec:
    ;load autoexec file to spam_buffer
    mov     dx, autoexec_fname

    mov     al, O_READ
    syscall SC_OPEN_FILE
    mov     dx, spam_buffer
    syscall SC_READ
    syscall SC_CLOSE_FILE

    test    cx, cx
    jz      run_autoexec_skip_autoexec
    
    cld
    mov     si, spam_buffer
  run_autoexec_loop:
    mov     dx, si

  run_autoexec_scan_loop:
    lodsb
    cmp     al, EOLN
    je      run_autoexec_eoln_found
    loop    run_autoexec_scan_loop
    jmp     run_autoexec_exit_loop
  run_autoexec_eoln_found:
    mov     byte[si-1], 0

    push    cx

    syscall SC_EXEC

    pop     cx

    jmp     run_autoexec_loop
  run_autoexec_exit_loop:

  run_autoexec_skip_autoexec:

    ret

start:
    ;initialize stack
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     ax, 7fffh
    mov     sp, ax

    ;load kernel
    mov     dl, 0       ;drive number (A = 0)
    mov     dh, 1       ;head
    mov     ch, 0       ;cylinder
    mov     cl, 3       ;sector
    mov     ax, 0000h   ;segment
    mov     es, ax      ;
    mov     al, 10      ;sector count
    mov     bx, 8000h   ;offset
    mov     ah, 2
    int     13h

    ;set interrupt vector
    cli
    mov     si, vect
    mov     word [vect], 8000h
    mov     word [vect+2], 0000h
    sti

    ;call kernel initialization function
    syscall 0ffh

    mov     dx, logo_fname
    mov     al, O_READ
    syscall SC_OPEN_FILE

    syscall SC_MALLOC
    push    es
    pop     ds

    xor     dx, dx
    syscall SC_READ
    syscall SC_PUTS
    syscall SC_CLOSE_FILE
    syscall SC_FREE

    push    cs
    pop     ds

    ;display 'Welcome' message
    mov     dx, msg_welcome
    syscall SC_PUTS

    ;get os info string
    mov     dx, spam_buffer
    syscall SC_GET_VER
    
    ;print os info
    syscall SC_PUTS

    ;print EOLN
    mov     al, EOLN
    syscall SC_PUTC

    call    run_autoexec

    ;run shell
    mov     dx, shell_fname
    syscall SC_EXEC

    mov     dx, shutdown_msg
    syscall SC_PUTS

    ;wait for any key
    syscall SC_GETC
    
    ;reboot
    mov     ax, 0040h
    mov     ds, ax
    mov     word [cs:0072h], 0000h
    jmp     0ffffh:0000h       

buffer = 0000h
dseg = 0500h

spam_buffer:
	spam	db (7dfeh - $) dup (0)
	db		55h, 0aah
;-- vim: set filetype=fasm:
