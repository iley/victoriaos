; VictoriaOS: list directory program

org 100h
include 'victoria.inc'
    jmp     start

    DISTANCE		equ	40

    std_text_attr   db	?
    filename		db	DISTANCE dup (' '), 0

    TA_EXEC     equ 04h
    TA_NORM     equ 07h

start:
	mov		bx, ds
    syscall SC_GET_TEXT_ATTR
    mov     [std_text_attr], al

    syscall SC_OPEN_DIR
    mov     dx, filename
loop0:
	mov		di, filename
	mov		cx, DISTANCE
	mov		al, ' '
	rep		stosb

    ;read directory
    syscall SC_READ_DIR
    
    test    ax, ATTR_EXEC
    jz      set_norm_attr
    mov     al, TA_EXEC
    syscall SC_SET_TEXT_ATTR
    jmp     attr_endif
  set_norm_attr:
    mov     al, TA_NORM
    syscall SC_SET_TEXT_ATTR
  attr_endif:

    ;check for eof
    syscall SC_EOF
    test    ax, ax
    jnz     exit

    ;print file name
    syscall SC_PUTS

    mov		al, EOLN
    syscall	SC_PUTC
    jmp		loop0
exit:
    syscall SC_CLOSE_DIR

    mov     al, [std_text_attr]
    syscall SC_SET_TEXT_ATTR
    ret
;-- vim: set filetype=fasm:
