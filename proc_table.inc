; VictoriaOS: kernel function table
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

;================================================
proc_table  dw  get_ver     ; 00
            dw  getc        ; 01
            dw  putc        ; 02
            dw  gets        ; 03
            dw  puts        ; 04
            dw  exec        ; 05
            dw  terminate   ; 06
            dw  malloc      ; 07
            dw  free        ; 08
            dw  get_vect    ; 09
            dw  set_vect    ; 0A
            dw  open_file   ; 0B
            dw  fgetc       ; 0C
            dw  feof        ; 0D
            dw  read        ; 0E
            dw  fputc       ; 0F
            dw  close_file  ; 10
            dw  get_err_msg ; 11
            dw  set_err_mode; 12
            dw  delete_file ; 13
            dw  get_attr    ; 14
            dw  set_attr    ; 15
            dw  rename      ; 16
            dw  default     ;!! TODO: FILL 17
            dw  get_size    ; 18
            dw  tsr         ; 19
            dw  open_dir    ; 1A
            dw  read_dir    ; 1B
            dw  close_dir   ; 1C
            dw  write       ; 1D
            dw  file_exists ; 1E
            dw  get_text_attr; 1F
            dw  set_text_attr; 20
            dw  0feh - 20h dup (default)
            dw  init        ; FF
