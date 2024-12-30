; VictoriaOS: file removing program

org 100h
include 'victoria.inc'
jmp     start

msg_error db 'ERROR: Not enough command line parameters', 13, 0

error:
    mov     dx, msg_error
    syscall SC_PUTS
    ret

start:
    mov     si, 0080h
    cld
scan_loop:
    lodsb
    test    al, al
    jz      error
    cmp     al, ' '
    jz      scan_found
    jmp     scan_loop
scan_found:

magic_loop:
    ;si is a start of the file name
    mov     dx, si

  scan_loop1:
    lodsb
    test    al, al
    jz      exit_scan_loop1
    cmp     al, ' '
    jz      scan_found1
    jmp     scan_loop1
  scan_found1:
    mov     byte[si-1], 0
    jmp     rem_file
  exit_scan_loop1:
    syscall SC_DELETE_FILE
    syscall SC_TERMINATE

rem_file:
    syscall SC_DELETE_FILE

    jmp     magic_loop

    ret
buffer:
;-- vim: set filetype=fasm:
