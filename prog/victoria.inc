; VictoriaOS: standart header for the user's programs under VictoriaOS

macro syscall num
{
    mov     ah, num
    int     50h
}

;================================================
; 
SC_GET_VER              equ     00h
SC_GETC                 equ     01h
SC_PUTC                 equ     02h
SC_GETS                 equ     03h
SC_PUTS                 equ     04h
SC_EXEC                 equ     05h
SC_TERMINATE            equ     06h
SC_MALLOC               equ     07h
SC_FREE                 equ     08h
SC_GET_VECT             equ     09h
SC_SET_VECT             equ     0ah
SC_OPEN_FILE            equ     0bh
SC_FGETC                equ     0ch
SC_EOF                  equ     0dh
SC_READ                 equ     0eh
SC_FPUTC                equ     0fh
SC_CLOSE_FILE           equ     10h
SC_GET_ERR_MSG          equ     11h
SC_SET_ERR_MODE         equ     12h
SC_DELETE_FILE          equ     13h
SC_GET_ATTR             equ     14h
SC_SET_ATTR             equ     15h
SC_RENAME               equ     16h
;SC_SOMETHING            equ     17h
SC_GET_SIZE             equ     18h
SC_TSR                  equ     19h
SC_OPEN_DIR             equ     1ah
SC_READ_DIR             equ     1bh
SC_CLOSE_DIR            equ     1ch
SC_WRITE                equ     1dh
SC_FILE_EXISTS          equ     1eh
SC_GET_TEXT_ATTR        equ     1fh
SC_SET_TEXT_ATTR        equ     20h

;================================================
; boolean constants
TRUE                    equ     0ffffh
FALSE                   equ     00000h

;================================================
; ASCII control codes
TAB                     equ     7
BACKSP                  equ     8
EOLN                    equ     13

;================================================
; file open modes
O_NONE                  equ     0
O_READ                  equ     1
O_WRITE                 equ     2
O_APPEND                equ     3 ; not used, reserved for the future
O_READDIR               equ     4

;================================================
; file attributes
ATTR_READ               equ     0000001b
ATTR_WRITE              equ     0000010b
ATTR_EXEC               equ     0000100b
ATTR_SYSTEM             equ     0001000b

;================================================
; error codes
ERR_NONE                equ     0
ERR_MALLOC              equ     1
ERR_FREE                equ     2
ERR_NO_FUNC             equ     3
ERR_DISK                equ     4
ERR_TOO_MANY_FILES      equ     5
ERR_FILE_OPENED         equ     6
ERR_FILE_NOT_EXIST      equ     7
ERR_INVALID_O_MODE      equ     8
ERR_ACCESS_DENIED       equ     9
ERR_INVALID_F_MODE      equ     10  ;trying to read file if file_mode is O_WRITE or write if...
ERR_EOF                 equ     11
ERR_INVALID_CLUST       equ     12
ERR_INVALID_FC_PARAM    equ     13
ERR_NO_FREE_CLUST       equ     14
ERR_FILE_NOT_OPENED     equ     15
ERR_FILE_EXIST          equ     16
ERR_FNAME_LEN           equ     17

;================================================
; display constnts
SCR_WIDTH  equ 80
SCR_HEIGHT equ 25

;================================================
; error hadnling modes
EM_HIDE             equ   00000000b
EM_SHOW             equ   00000001b ;display error messages
EM_TERMINATE        equ   00000010b ;terminate program
;-- vim: set filetype=fasm:
