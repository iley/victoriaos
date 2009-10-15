; VictoriaOS: miscellaneous constants
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

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

ATTR_STD                equ     ATTR_READ or ATTR_WRITE

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
; keybord status flags
KBD_SHIFT               equ     00000011b
KBD_LSHIFT              equ     00000001b
KBD_RSHIFT              equ     00000010b
KBD_CTRL                equ     00000100b
KBD_ALT                 equ     00001000b
KBD_SCROLL              equ     00010000b
KBD_NUM                 equ     00100000b
KBD_CAPS                equ     01000000b
KBD_INS                 equ     10000000b

;================================================
; display constants
SCR_WIDTH               equ     80
SCR_HEIGHT              equ     25

;================================================
; memory constants
FIRST_SEG               equ      1000h       ;first empty segment
LAST_SEG                equ     0f000h
SEG_NUM                 equ     15

;================================================
; version info
VER_MAJOR               equ     0
VER_RELEASE             equ     2
ver_info                db      'Victoria OS, version 0.03, written by Strukov I.V.', 0

;================================================
; misc
FIRST_KBD_CHAR          equ     30
DEF_VIDEO_MODE          equ     3
;-- vim: set filetype=fasm:
