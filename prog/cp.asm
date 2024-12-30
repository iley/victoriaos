; VictoriaOS: copy file program

org 100h
include 'victoria.inc'

jmp     start

    msg_error       db 'ERROR: Not enough command line parameters', 13, 0
    msg_dst_exists  db 'ERROR: Destination file is already exists', 13, 0

    attr    dw ?

error:
    mov     dx, msg_error
    syscall SC_PUTS
    ret

start:
    mov     si, 0080h
    cld

scan_loop0:
    lodsb
    test    al, al
    jz      error
    cmp     al, ' '
    jz      scan_found0
    jmp     scan_loop0
scan_found0:
    ;si is a start of the file name
    mov     dx, si

scan_loop1:
    lodsb
    test    al, al
    jz      error
    cmp     al, ' '
    jz      scan_found1
    jmp     scan_loop1
scan_found1:
    mov     byte[si-1], 0
    ;si is a start of the file name

    syscall SC_GET_ATTR
    mov     [attr], ax
    
    mov     al, O_READ
    syscall SC_OPEN_FILE

    mov     dx, buffer
    syscall SC_READ
    syscall SC_CLOSE_FILE

    mov     dx, si

    syscall SC_FILE_EXISTS
    test    ax, ax
    jz      dst_file_not_exists
    mov     dx, msg_dst_exists
    syscall SC_PUTS
    ret
  dst_file_not_exists:

    mov     al, O_WRITE
    push    cx
    syscall SC_OPEN_FILE
    pop     cx
    
    mov     dx, buffer
    syscall SC_WRITE
    syscall SC_CLOSE_FILE

    mov     dx, si
    mov     cx, [attr]
    syscall SC_SET_ATTR

    ret

buffer:
;-- vim: set filetype=fasm:
