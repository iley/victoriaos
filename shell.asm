; VictoriaOS: simple shell v0.02
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

org 100h

jmp     start

include 'stdlib/string/strlen.inc'
include 'stdlib/string/strcmp.inc'
include 'stdlib/string/strcpy.inc'
include 'victoria.inc'

    FIRST_PRINT_CHAR equ 32
    KEY_REPEAT  equ 72  ;up arrow

    buf_start   dw  ?
    
    msg_welcome db 'Victoria Shell 0.02', EOLN, 0
    msg_prompt  db '# ', 0
    
    cmd_exit    db 'exit', 0

    start_col   db ?
    start_row   db ?

start:  
    mov     dx, EM_SHOW
    syscall SC_SET_ERR_MODE
    
    mov     dx, msg_welcome
    syscall SC_PUTS

    mov     byte[cmd_buffer], 0

  main_loop:
    push    ds
    pop     es

    mov     dx, msg_prompt
    syscall SC_PUTS

    ;save cursor position
    mov     ah, 03h
    mov     bh, 00h
    int     10h
    mov     [start_row], dh
    mov     [start_col], dl

    mov     di, new_buffer
    cld
  read_char:
    mov     ah, 00h
    int     16h

    ;check for the RETURN
    cmp     al, EOLN
    jne     read_char_not_return
    mov     al, EOLN
    syscall SC_PUTC
    jmp     read_char_end
  read_char_not_return:

    ;check for the BACKSPACE
    cmp     al, BACKSP
    jne     read_char_not_back
    cmp     di, new_buffer
    jbe     read_char_not_back
    dec     di
    syscall SC_PUTC
  read_char_not_back:

    ;check for extended ASCII
    test    al, al
    jnz     read_char_not_ext
    ;check for the UP_ARROW
    cmp     ah, KEY_REPEAT
    jne     read_char_not_repeat
    
    mov     dh, [start_row]
    mov     dl, [start_col]
    mov     bh, 0
    mov     ah, 02h
    int     10h

    ;get current length
    mov     cx, di
    sub     cx, new_buffer

    ;print cx spaces to clear line
    mov     al, ' '
  read_char_print_space:
    test    cx, cx
    je      read_char_print_space_end
    syscall SC_PUTC
    dec     cx
    jmp     read_char_print_space
  read_char_print_space_end:

    mov     ah, 02h
    int     10h

    mov     si, cmd_buffer
    call    strlen
    mov     di, new_buffer
    call    strcpy

    ;print
    mov     dx, di
    syscall SC_PUTS
    
    add     di, cx

  read_char_not_repeat:

    jmp     read_char
  read_char_not_ext:

    ;do not show non-printable characters
    cmp     al, FIRST_PRINT_CHAR
    jb      read_char

    stosb
  read_char_print:
    syscall SC_PUTC
    jmp     read_char
  read_char_end:

    mov     byte[di], 0

    mov     si, new_buffer
    mov     di, buffer
    call    strcpy

    mov     si, buffer
    mov     di, cmd_exit
    call    strcmp
    jz      main_loop_exit

    mov     si, buffer
    mov     di, cmd_buffer

  buffer_loop:

  skip_spaces_loop:
    lodsb
    cmp     al, ' '
    jz      skip_spaces_loop
    dec     si

  copy_loop:
    lodsb
    stosb
    cmp     al, ' '
    jz      exit_copy_loop
    test    al, al
    jz      exit_buffer_loop
    jmp     copy_loop
  exit_copy_loop:
    jmp     buffer_loop

  exit_buffer_loop:

    cmp     byte[di-2], ' '
    jne     no_spam_spaces
    mov     byte[di-2], 0
  no_spam_spaces:

    mov     si, cmd_buffer
    mov     di, buffer
  copy_word_loop:
    lodsb
    stosb
    cmp     al, ' '
    jz      exit_copy_word_loop
    test    al, al
    jz      exit_copy_word_loop
    jmp     copy_word_loop
  exit_copy_word_loop:
    mov     byte[di-1], 0

    ; run program
    pusha
    push    ds es
    mov     dx, buffer
    mov     cx, cmd_buffer
    syscall SC_EXEC
    pop     es ds
    popa

    ; display entered command for the test
;    mov     dx, cmd_buffer
;    syscall SC_PUTS
;    mov     al, '|'
;    syscall SC_PUTC
;    mov     al, EOLN
;    syscall SC_PUTC

;    mov     dx, buffer
;    syscall SC_PUTS
;    mov     al, '|'
;    syscall SC_PUTC
;    mov     al, EOLN
;    syscall SC_PUTC
    
    jmp     main_loop
  main_loop_exit:

    ret
cmd_buffer=$
sizeof.cmd_buffer=100h
buffer=cmd_buffer+sizeof.cmd_buffer
sizeof.buffer=100h
new_buffer=buffer+sizeof.buffer
sizeof.new_buffer=100h
