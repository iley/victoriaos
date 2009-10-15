; VictoriaOS: error handling module
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

;================================================
; error printing macro
macro error err_code
{
    push    ax
    mov     ax, err_code
    mov     word[cs:last_error], ax
    pop     ax

    mov     ax, word[cs:sp_backup]
    mov     sp, ax
    pop     ax
    jmp     int_exit

}

; error hadnling modes
EM_HIDE             equ   00000000b
EM_SHOW             equ   00000001b ;display error messages
EM_TERMINATE        equ   00000010b ;terminate program

; error handling mode: EM_HIDE, EM_SHOW
DEF_ERR_MODE        equ EM_SHOW or EM_TERMINATE
err_mode            dw  DEF_ERR_MODE

ERR_NONE              equ     0
ERR_MALLOC            equ     1
ERR_FREE              equ     2
ERR_NO_FUNC           equ     3
ERR_DISK              equ     4
ERR_TOO_MANY_FILES    equ     5
ERR_FILE_OPENED       equ     6
ERR_FILE_NOT_EXIST    equ     7
ERR_INVALID_O_MODE    equ     8
ERR_ACCESS_DENIED     equ     9
ERR_INVALID_F_MODE    equ     10  ;trying to read file if file_mode is O_WRITE or write if...
ERR_EOF               equ     11
ERR_INVALID_CLUST     equ     12
ERR_INVALID_FC_PARAM  equ     13
ERR_NO_FREE_CLUST     equ     14
ERR_FILE_NOT_OPENED   equ     15
ERR_FILE_EXIST        equ     16
ERR_FNAME_LEN         equ     17
ERR_TOO_BIG_FILE      equ     18

err_table   dw  emsg_none
      dw  emsg_malloc
      dw  emsg_free
      dw  emsg_no_func
      dw  emsg_disk
      dw  emsg_too_many_files
      dw  emsg_file_opened
      dw  emsg_file_not_exist
      dw  emsg_invalid_o_mode
      dw  emsg_access_denied
      dw  emsg_invalid_f_mode
      dw  emsg_eof
      dw  emsg_invalid_clust
      dw  emsg_invalid_fc_param
      dw  emsg_no_free_clust
      dw  emsg_file_not_open
      dw  emsg_file_exist
      dw  emsg_fname_len
      dw  emsg_too_big_file

msg_error             db 'ERROR: ', 0

emsg_none             db 'No errors', EOLN, 0
emsg_malloc           db 'Out of memory', EOLN, 0
emsg_free             db 'Wrong segment for freeing', EOLN, 0
emsg_no_func          db 'Wrong kernel function number', EOLN, 0
emsg_disk             db 'Disk I/O error', EOLN, 0
emsg_too_many_files   db 'There is too many files in the root directory', EOLN, 0
emsg_file_opened      db 'File is already opened', EOLN, 0
emsg_file_not_exist   db 'File does not exist', EOLN, 0
emsg_invalid_o_mode   db 'Invalid file mode for OPEN', EOLN, 0
emsg_access_denied    db 'Access denied', EOLN, 0
emsg_invalid_f_mode   db 'Invalid file mode', EOLN, 0
emsg_eof              db 'Reading after end of file', EOLN, 0
emsg_invalid_clust    db 'Invalid cluster number', EOLN, 0
emsg_invalid_fc_param db 'Invalid parameter in FILECTL', EOLN, 0
emsg_no_free_clust    db 'No free space on disk', EOLN, 0
emsg_file_not_open    db 'File is not open', EOLN, 0
emsg_file_exist       db 'File is already exists', EOLN, 0
emsg_fname_len        db 'Wrong file name', 27h,'s length', EOLN, 0
emsg_too_big_file     db 'Too big file', EOLN, 0
;-- vim: set filetype=fasm:
