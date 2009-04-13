; VictoriaOS: file system support module
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

;================================================
; data structures
struct inode
inode_start:
        inode_name = 0
    name db 10 dup (?)
        inode_attr = 10
    attr dw ?
        inode_size = 12
    size dw ?
        inode_sect = 14
    clust dw ?
ends
;================================================
; constants
    FAT_EOF         equ 0ffffh
    FAT_FREE        equ 0
    FAT_ITEM_SIZE   equ 2
    
    EMPTY_FILE_CHAR equ 0

    HEAD_COUNT      equ 2
    SECT_COUNT      equ 18
    CYL_COUNT       equ 80
    SECT_PER_HEAD   equ 1440
    LAST_CLUST      equ (SECT_PER_HEAD * HEAD_COUNT)
    BYTES_PER_CLUST equ 512

    FAT_START       equ 2
    FAT_LEN         equ 12
    DIR_START       equ 14
    DIR_LEN         equ 2
    DATA_START      equ (DIR_START + DIR_LEN + 1) ; +1 - подгон
    
    RESERVED_CLUST  equ (1 + FAT_LEN + DIR_LEN)

    MAX_FILE_NAME_LEN equ 9
    MAX_FILE_SIZE   equ 0ffffh

;================================================
;
    ;declared in kernel.asm
    ;fat                dw FAT_LEN * BYTES_PER_CLUST / 2 dup (?)
    ;io_buf         db BYTES_PER_CLUST  dup (?)                 ; input/output buffer
    
    buf_ptr         dw io_buf + BYTES_PER_CLUST                 ; read/write position in io_buf
    file_mode       dw 0
    next_clust      dw FAT_EOF
    prev_clust      dw FAT_EOF
    is_eof          dw 0
    bytes_left      dw 0
    inode_clust     dw ?
    inode_addr      dw ?
    file_size       dw ?
    cur_clust       dw ?
    
;================================================
; #proc convert cluster number to real (head/cylinder/sector) coordinates
; #input: ax - cluster
; #output: dl - 0 (drive number), dh - head, ch - cylinder, cl - sector
cluster_coord:
    push    ax bx
    
    dec     ax  ;set cluster number to 0..17

    xor     dx, dx
    mov     bx, SECT_COUNT
    div     bx
    mov     cl, dl  ;!!sector number
    inc     dl      ;set sector number to 1..18
    inc     cl
    
    test    ax, 1   ;if sector number is odd, side is 0
    jnz     cluster_coord_side1

  cluster_coord_side0:
    mov     dh, 0   ;side is 0
    jmp     cluster_coord_exit

  cluster_coord_side1:
    mov     dh, 1   ;side is 1
    jmp     cluster_coord_exit
  
  cluster_coord_exit:   
    shr     ax, 1
    mov     ch, al  ;!!cylinder
    mov     dl, 0   ;!!drive is always 0

    pop     bx ax
    ret

;================================================
; #proc read cluster function
; #input: es:dx - buffer address, ax - cluster number
read_clust:
    push    ax bx cx dx es
    cmp     ax, LAST_CLUST
    jbe     read_clust_no_error
    error   ERR_INVALID_CLUST
  read_clust_no_error:
    push    ds
    pop     es
    mov     bx, dx
    call    cluster_coord
    mov     ax, 0201h
    int     13h
    jnc     read_clust_no_disk_error
    error   ERR_DISK
  read_clust_no_disk_error:
    pop     es dx cx bx ax
    ret

;================================================
; #proc read block function
; #input: es:dx - buffer address, ax - cluster number, cl - cluster count
; #output:   ax != 0, if successful
read_block:
    push    ax bx cx dx es
    push    cx
    push    ds
    pop     es
    mov     bx, dx
    call    cluster_coord
    pop     ax
    mov     ah, 02h
    int     13h
    jnc     read_block_no_error
    error   ERR_DISK
  read_block_no_error:
    pop     es dx cx bx ax
    ret

;=================================================
; #proc write cluster
; #input: ax - cluster number, ds:dx - buffer
write_clust:
    push    ax bx cx dx es
    push    ds
    pop     es
    mov     bx, dx  
    call    cluster_coord
    mov     ax, 0301h
    int     13h
    jnc     write_clust_no_error
    error   ERR_DISK
  write_clust_no_error:
    pop     es dx cx bx ax
    ret

;=================================================
; #proc write block
; #input: ax - cluster number, ds:dx - buffer, cl - cluster count
write_block:
    push    ax bx cx dx es
    push    ds
    pop     es
    mov     bx, dx
    push    cx
    call    cluster_coord
    pop     ax
    mov     ah, 03h
    int     13h
    jnc     write_block_no_error
    error   ERR_DISK
  write_block_no_error:
    pop     es dx cx bx ax
    ret

;================================================
; #proc initialize file system
init_fs:
    call    read_fat
    ret

;================================================
; #proc find inode (used in find_file and other functions)
; #input:    ds:dx - file name
; #output:   si - inode address in io_buf, ax - cluster number, if successful
;           si = 0, if not successful
find_inode:
    push    bx cx dx di ds es
    push    ds
    pop     es
    push    cs
    pop     ds
    mov     ax, DIR_START   
  find_inode_loop0:
    cmp     ax, DIR_START + DIR_LEN
    jae     find_inode_not_found

    push    dx
    mov     dx, io_buf
    call    read_clust
    pop     dx
    
    mov     cx, BYTES_PER_CLUST / sizeof.inode
    mov     si, io_buf
    mov     di, dx  
  find_inode_loop1:
    mov     bl, [si]
    cmp     bl, EMPTY_FILE_CHAR
    je      find_inode_skip
    call    strcmp
    je      find_inode_exit
  find_inode_skip:
    add     si, sizeof.inode
    loop    find_inode_loop1

    inc     ax
    jmp     find_inode_loop0
  find_inode_not_found:
    xor     si, si
  find_inode_exit:
    pop     es ds di dx cx bx
    ret

;================================================
; #proc find file 
; #input:    ds:dx - file name
; #output:   if successful, dx - first file's cluster number, ax - file attributes, cx - file size
;           if not successful dx = 0
find_file:
    push    si
    call    find_inode
    test    si, si
    jnz     find_file_no_error
    xor     dx, dx
    jmp     find_file_exit
  find_file_no_error:   
    mov     dx, [cs:si+inode_sect]
    mov     ax, [cs:si+inode_attr]
    mov     cx, [cs:si+inode_size]
  find_file_exit:
    pop     si
    ret

;=================================================
; #proc create file (used only from open_file)
; #input: ds:dx - file name, ax - attributes
; #output: dx = first cluster
create_file:
    push    ax bx cx si di ds es

    push    dx      ;save filename  
    push    ax      ;save attributes
;   ----------
    
    mov     ax, DIR_START

    push    ds
    pop     es  

  create_file_loop0:
    cmp     ax, DIR_START + DIR_LEN
    jae     create_file_not_found

    push    ds

    push    cs
    pop     ds

    mov     dx, io_buf
    call    read_clust
    pop     ds
    
    mov     cx, BYTES_PER_CLUST / sizeof.inode
    mov     si, dx
  create_file_loop1:
    mov     bl, [cs:si]
    cmp     bl, EMPTY_FILE_CHAR
    je      create_file_found
    add     si, sizeof.inode
    loop    create_file_loop1

    inc     ax
    jmp     create_file_loop0
  create_file_not_found:
    error   ERR_TOO_MANY_FILES
    jmp     find_file_exit
  create_file_found:

    mov     [cs:inode_addr], si
    mov     [cs:inode_clust], ax
    
    pop     bx      ;restore attributes
;   ----------
    
    mov     di, si
    pop     si      ;restore filename
;   ----------

    push    es
    pop     ds

    push    cs
    pop     es

    call    strcpy
    mov     [cs:di+inode_attr], bx
    xor     bx, bx
    mov     [cs:di+inode_size], bx
    call    alloc_clust
    mov     bx, dx
    mov     [cs:di+inode_sect], bx


    ;write directory cluster (ax=cluster number)
    push    cs
    pop     ds
    mov     dx, io_buf
    call    write_clust

    mov     ax, bx
    call    fat_addr
    mov     word[cs:si], FAT_EOF
    call    write_fat
    
 create_file_exit:
    mov     dx, bx
    pop     es ds di si cx bx ax
    ret
    
;=================================================
; #proc allocate cluster
; #output: dx - cluster number
alloc_clust:
    push    ax bx cx di es
    push    cs
    pop     es
    mov     di, fat + (DATA_START * FAT_ITEM_SIZE)
    mov     cx, FAT_LEN * BYTES_PER_CLUST / FAT_ITEM_SIZE - DATA_START
    ;scan fat for the free sectors
    mov     ax, FAT_FREE
    cld
    repne   scasw
    je      alloc_clust_no_error
    error   ERR_NO_FREE_CLUST
  alloc_clust_no_error:
    mov     ax, di
    sub     ax, fat + FAT_ITEM_SIZE
    mov     bx, FAT_ITEM_SIZE
    xor     dx, dx
    div     bx
    mov     dx, ax
    pop     es di cx bx ax
    ret

;=================================================
; #proc close file
close_file:
    push    ax cx dx si ds

    push    cs
    pop     ds

    mov     ax, [file_mode]
    cmp     ax, O_READ
    je      close_file_read
    cmp     ax, O_WRITE
    je      close_file_write
    error   ERR_FILE_NOT_OPENED

  close_file_read:
    jmp     close_file_exit
  close_file_write:
    ;write last bytes to file
    call    flush_io_buf

    ;write file size to the directory table
    mov     ax, [inode_clust]
    mov     dx, io_buf
    call    read_clust

    mov     si, [inode_addr]
    mov     cx, [bytes_left]
    mov     [si+inode_size], cx
    call    write_clust

    ;write FAT_EOF
    mov     ax, [prev_clust]
    call    fat_addr
    mov     word[si], FAT_EOF
    call    write_fat

    ;jmp  close_file_exit

  close_file_exit:
    mov     [file_mode], O_NONE
  
    pop     ds si dx cx ax
    ret

;=================================================
; #proc open file
; (only one file can be opened at any time)
; #input: ds:dx - file name, al - open mode (O_READ, O_WRITE)
; #output: ax - file attributes, cx - file size
open_file:
    push    bx dx si di bp
    
    ;check if user can open any file (only one file can be opened at any time)
    mov     bx, O_NONE
    cmp     [cs:file_mode], bx
    je      open_file_can_open
    error   ERR_FILE_OPENED
  open_file_can_open:

    mov     si, dx
    call    strlen
    cmp     cx, MAX_FILE_NAME_LEN
    jb      open_file_len_ok
    error   ERR_FNAME_LEN
  open_file_len_ok:

    mov     di, dx  ;save filename for creating if it will be needed
    mov     bl, al  ;save file open mode
  
    call    find_inode
    test    si, si
    jnz     open_file_found
    xor     dx, dx
    jmp     open_file_not_found
  open_file_found:   
    mov     [cs:inode_addr], si
    mov     [cs:inode_clust], ax
    mov     dx, [cs:si+inode_sect]
    mov     ax, [cs:si+inode_attr]
    mov     bp, ax  ;save file attributes
    mov     cx, [cs:si+inode_size]
  open_file_not_found:

    cmp     bl, O_READ
    je      open_file_read
    cmp     bl, O_WRITE
    je      open_file_write
    error   ERR_INVALID_O_MODE
  
  open_file_read:
    test    dx, dx
    jnz     open_file_read_exist
    error   ERR_FILE_NOT_EXIST
  open_file_read_exist:
    test    ax, ATTR_READ   ;check if user can read this file
    jnz     open_file_can_read
    error   ERR_ACCESS_DENIED
  open_file_can_read:
    mov     ax, io_buf + BYTES_PER_CLUST
    mov     [cs:buf_ptr], ax   ;clear io buffer (io_buf)
    jmp     open_file_success
  
  open_file_write:
    test    dx, dx
    jnz     open_file_write_exist
    ;file not exist: create new one
    mov     dx, di
    mov     ax, ATTR_STD
    call    create_file
    jmp     open_file_write_clear 
  open_file_write_exist:
    mov     ax, dx
    call    empty_file
    call    fat_addr
    mov     ax, FAT_EOF
    mov     [cs:si], ax
  
  open_file_write_clear:
    test    ax, ATTR_WRITE  ;check if user can write to the file
    jnz     open_file_can_write
    error   ERR_ACCESS_DENIED
  open_file_can_write:
    mov     ax, io_buf
    mov     [cs:buf_ptr], ax   ;clear io buffer (io_buf)
    xor     cx, cx
    jmp     open_file_success

  open_file_success:
    mov     [cs:file_mode], bx
    mov     [cs:next_clust], dx ;I used next_clust in reading, but after I added prev_clust for writing
    ;mov    [prev_clust], dx
    ;set byte counter for reading (it is not necessary for writing)
    mov     [cs:bytes_left], cx
    mov     [cs:file_size], cx
    
    ;check for eof (is file empty?)
    test    cx, cx
    jnz     open_file_no_eof
  open_file_eof:
    mov     word[cs:is_eof], TRUE
    jmp     open_file_eof_check_end
  open_file_no_eof:
    mov     [cs:is_eof], FALSE
  open_file_eof_check_end:
    mov     ax, bp
    pop     bp di si dx bx
    ret
    
;=================================================
; #proc get fat element's address
; #input: ax - cluster's number
; #output: si - element's address
fat_addr:
    mov     si, ax
    shl     si, 1
    add     si, fat
    ret

;=================================================
; #proc get next cluster number from fat
; #input: ax - cluster number
; #output: ax - next cluster number
get_clust:
    push    si
    call    fat_addr
    mov     ax, [cs:si]
    pop     si
    ret

;=================================================
; #proc check for the end of file
; #output:   ax = 0, if no eof
;           ax is not 0, if eof
feof:
    mov     ax, [cs:file_mode]
    cmp     ax, O_READ
    je      eof_no_error
    cmp     ax, O_READDIR
    je      eof_no_error
    error   ERR_INVALID_F_MODE
  eof_no_error:
    mov     ax, [cs:is_eof]
    ret

;=================================================
; #proc read a character from the file
; #output: al - character
fgetc:
    push    si
    mov     ax, [cs:file_mode]
    cmp     ax, O_READ
    je      fgetc_can_read
    error   ERR_INVALID_F_MODE
  fgetc_can_read:
    mov     ax, [cs:bytes_left]
    test    ax, ax
    jnz     fgetc_no_eof_err
    error   ERR_EOF
  fgetc_no_eof_err:
    mov     ax, [cs:buf_ptr]
    cmp     ax, io_buf + BYTES_PER_CLUST
    jb      fgetc_buf_not_empty
    call    fill_io_buf
  fgetc_buf_not_empty:      
    dec     [cs:bytes_left]
    jnz     fgetc_no_eof
    mov     [cs:is_eof], TRUE
  fgetc_no_eof:
    mov     si, [cs:buf_ptr]
    inc     [cs:buf_ptr]
    mov     al, [cs:si]
    pop     si
    ret

;=================================================
; #proc read next_clust to io_buf and update next_clust
fill_io_buf:
    push    ax dx ds
    push  cs
    pop   ds
    mov     ax, [cs:next_clust]
    mov     dx, io_buf
    call    read_clust
    call    get_clust
    mov     [cs:next_clust], ax
    mov     ax, io_buf
    mov     [cs:buf_ptr], ax
    pop     ds dx ax
    ret

;=================================================
; #proc write io_buf to next_clust and update next_clust and prev_clust
flush_io_buf:
    push    ax dx ds
    push    cs
    pop     ds
    mov     ax, [next_clust]

    cmp     ax, FAT_EOF
    jne     flush_io_buf_alloc_not_need
  
    call    alloc_clust
    mov     [next_clust], dx
    mov     ax, [prev_clust]
    call    fat_addr
    mov     [si], dx
    mov     ax, dx
    call    fat_addr
    mov     word[si], FAT_EOF
    call    write_fat
    ;ax is a new next_clust

  flush_io_buf_alloc_not_need:
    mov     dx, io_buf
    call    write_clust
    mov     [prev_clust], ax
    call    get_clust
    mov     [next_clust], ax
    mov     ax, io_buf
    mov     [buf_ptr], ax
    pop     ds dx ax
    ret

;=================================================
; #proc read block from the file
; #input: ds:dx - buffer, cx - number of bytes to read
read:
    push    ax cx dx si di ds es
    mov     di, dx  ;di = buffer address
    mov     dx, cx  ;dx = bytes to read

    ;set segments for copying (from cs:si to ds:di)
    push    ds
    pop     es
    push    cs
    pop     ds
    
    cmp     word[cs:file_mode], O_READ
    je      read_can_read
    error   ERR_INVALID_F_MODE
  read_can_read:
    mov     ax, [cs:bytes_left]
    cmp     ax, cx
    jae     read_no_eof_err
    error   ERR_EOF
  read_no_eof_err:
    cmp     word[cs:buf_ptr], io_buf + BYTES_PER_CLUST
    jb      read_buf_not_empty
    call    fill_io_buf
  read_buf_not_empty:       
  read_loop0:
    mov     si, io_buf  ;source is io_buf  
    mov     ax, io_buf + BYTES_PER_CLUST
    sub     ax, [cs:buf_ptr]
    cmp     dx, ax
    jbe     read_dx_lower
    mov     cx, ax
    jmp     read_copy
  read_dx_lower:
    mov     cx, dx

  read_copy:
    sub     dx, cx      ;refresh dx (bytes left)
    rep     movsb       ;copy min(left bytes to read, buf_ptr - io_buf) bytes from io_buf to user's buffer
    test    dx, dx
    jz      read_exit
    call    fill_io_buf ;ERROR
    jmp     read_loop0
  read_exit:
    pop     es ds di si dx cx ax
    ret

;=================================================
; #proc clear clusters in file allocation table (fat), leave one cluster
; #input: ax - first cluster's number
empty_file:
    push    ax bx si
    call    fat_addr
    mov     ax, [cs:si]
    mov     word[cs:si], FAT_EOF
    mov     bx, FAT_FREE
  empty_file_loop:
    test    ax, ax
    jnz     empty_file_no_error
    error   ERR_INVALID_CLUST
  empty_file_no_error:
    cmp     ax, FAT_EOF
    je      empty_file_exit
    call    fat_addr
    mov     ax, [cs:si]
    mov     [cs:si], bx
    jmp     empty_file_loop
  empty_file_exit:
    call    write_fat
    pop     si bx ax
    ret

;=================================================
; #proc clear cluster in FAT, do not leave one cluster
; #input: ax - first cluster
clear_fat:
    push    ax bx si
  clear_fat_loop:
    test    ax, ax
    jnz     clear_fat_no_error
    error   ERR_INVALID_CLUST
  clear_fat_no_error:
    call    fat_addr
    mov     ax, [cs:si]
    mov     word[cs:si], FAT_FREE
    cmp     ax, FAT_EOF
    jne     clear_fat_loop
    call    write_fat
    pop     si bx ax
    ret

;=================================================
; #proc write char
; #input: al - character
fputc:
    push    ax si

    cmp     [cs:bytes_left], MAX_FILE_SIZE
    jb      fputc_no_overflow
    error   ERR_TOO_BIG_FILE
  fputc_no_overflow:

    cmp     word[cs:file_mode], O_WRITE
    je      fputc_can_write
    error   ERR_INVALID_F_MODE
  fputc_can_write:

    cmp     word[cs:buf_ptr], io_buf+BYTES_PER_CLUST
    jb      fputc_buf_not_full
    call    flush_io_buf
  fputc_buf_not_full:

    mov     si, [cs:buf_ptr]
    mov     [cs:si], al
    inc     [cs:buf_ptr]
    inc     [cs:bytes_left]
    
    pop     si ax
    ret

;=================================================
; #proc set file's attributes
; #input: ds:dx - file name, cx - attribute
set_attr:
    push    ax dx si ds
    cmp     [cs:file_mode], O_NONE
    je      set_attr_right_mode
    error   ERR_INVALID_F_MODE
  set_attr_right_mode:
    call    find_inode
    test    si, si
    jnz     set_attr_exist
    error   ERR_FILE_NOT_EXIST
  set_attr_exist:
    mov     [cs:si+inode_attr], cx
    push    cs
    pop     ds
    mov     dx, io_buf
    call    write_clust
    pop     ds si dx ax
    ret

;=================================================
; #proc get file's attributes
; #output: ax - attributes
get_attr:
    push    si
    cmp     [cs:file_mode], O_NONE
    je      get_attr_right_mode
    error   ERR_INVALID_F_MODE
  get_attr_right_mode:
    call    find_inode
    test    si, si
    jnz     get_attr_exist
    error   ERR_FILE_NOT_EXIST
  get_attr_exist:
    mov     ax, [cs:si+inode_attr]
    pop     si
    ret

;=================================================
; #proc rename file
; #input: ds:dx - old file name, ds:cx - new file name
rename:
    push    ax dx si di ds es

    push    dx

    push    cx
    mov     si, cx
    call    strlen
    cmp     cx, MAX_FILE_NAME_LEN
    jb      rename_len_ok
    error   ERR_FNAME_LEN
  rename_len_ok:
    pop     cx

    mov     dx, cx
    call    find_inode
    test    si, si
    jz      rename_file_not_exist
    error   ERR_FILE_EXIST
  rename_file_not_exist:

    pop     dx

    cmp     [cs:file_mode], O_NONE
    je      rename_right_mode
    error   ERR_INVALID_F_MODE
  rename_right_mode:
    call    find_inode
    test    si, si
    jnz     rename_no_error
    error   ERR_FILE_NOT_EXIST
  rename_no_error:  
    push    cs
    pop     es
    lea     di, [si+inode_name]
    mov     si, cx
    call    strcpy

    push    cs
    pop     ds
    mov     dx, io_buf
    call    write_clust
    pop     es ds di si dx ax
    ret

;=================================================
; #proc read fat from disk to memory
read_fat:
    push    ax cx dx ds
    mov     ax, FAT_START
    mov     cl, FAT_LEN
    push    cs
    pop     ds
    mov     dx, fat
    call    read_block
    pop     ds dx cx ax
    ret

;=================================================
; #proc write fat from memory to disk
write_fat:
    push    ax cx dx ds
    mov     ax, FAT_START
    mov     cl, FAT_LEN
    push    cs
    pop     ds
    mov     dx, fat
    call    write_block
    pop     ds dx cx ax
    ret

;=================================================
; #proc delete file
; #input: ds:dx - file name
delete_file:
    push    ax dx si ds 
    cmp     [cs:file_mode], O_NONE
    je      delete_file_right_mode
    error   ERR_INVALID_F_MODE

  delete_file_right_mode:
    call    find_inode
    test    si, si
    jnz     delete_file_exist
    error   ERR_FILE_NOT_EXIST

  delete_file_exist:
    ;clear directory entry
    push    cs
    pop     ds

    push    ax
    mov     ax, [si+inode_sect]
    call    clear_fat
    mov     byte[si], EMPTY_FILE_CHAR
    mov     dx, io_buf
    pop     ax
    call    write_clust

    pop     ds si dx ax
    ret

;=================================================
; #proc get the size of the opened file
; #output: cx - size
get_size:
    mov     cx, [cs:file_size]
    ret

;=================================================
; #proc open directory
open_dir:
    cmp     word[cs:file_mode], O_NONE
    je      open_dir_right_mode
    error   ERR_FILE_OPENED
  open_dir_right_mode:
    mov     word[cs:buf_ptr], io_buf+BYTES_PER_CLUST
    mov     word[cs:cur_clust], DIR_START
    mov     word[cs:file_mode], O_READDIR
    mov     word[cs:is_eof], FALSE
    ret

;=================================================
; #proc close directory
close_dir:
    cmp     word[cs:file_mode], O_READDIR
    je      close_dir_right_mode
    error   ERR_FILE_NOT_OPENED
  close_dir_right_mode: 
    mov     word[cs:file_mode], O_NONE
    ret

;=================================================
; #proc read directory
; #input: ds:dx - buffer for name
; #output: cx - size, ax - attributes
read_dir:
    push    dx si di ds es
    push    ds
    pop     es
    push    cs
    pop     ds
    mov     ax, [cur_clust]
    mov     si, [buf_ptr]
    mov     di, dx
    mov     dx, io_buf
  read_dir_loop:
    cmp     si, io_buf + BYTES_PER_CLUST
    jb      read_dir_buf_not_empty
    cmp     ax, DIR_START + DIR_LEN
    jae     read_dir_eof
    call    read_clust
    inc     ax
    mov     si, io_buf
  read_dir_buf_not_empty:
    cmp     byte[si], EMPTY_FILE_CHAR
    jne     read_dir_found
    add     si, sizeof.inode
    jmp     read_dir_loop
  read_dir_eof:
    mov     word[is_eof], TRUE
;   error ERR_EOF
    jmp     read_dir_exit
  read_dir_found:
    mov     [cur_clust], ax
    call    strcpy
    mov     ax, [si+inode_attr]
    mov     cx, [si+inode_size]
    add     si, sizeof.inode
    mov     [buf_ptr], si
  read_dir_exit:
    pop     es ds di si dx
    ret

;=================================================
; #proc write block to file
; #input: ds:dx - buffer's address, cx - buffer size
write:
    push    ax cx si di ds es
    
    push    cs
    pop     es
    
    cmp     word[cs:file_mode], O_WRITE
    je      write_right_mode
    error   ERR_INVALID_F_MODE
  write_right_mode:

    test    cx, cx
    jz      write_exit

    mov     ax, [cs:bytes_left]
    add     ax, cx
    jno     write_no_overflow
    error   ERR_TOO_BIG_FILE
  write_no_overflow:

    add     [cs:bytes_left], cx

    cld
    mov     si, dx
    mov     di, [cs:buf_ptr]
  write_loop:

    cmp     di, io_buf+BYTES_PER_CLUST
    jb      write_buf_not_full
    call    flush_io_buf
    mov     di, io_buf
  write_buf_not_full:

    movsb
    loop    write_loop

    mov     [cs:buf_ptr], di

  write_exit:
    pop     es ds di si cx ax
    ret

;=================================================
; #proc check if file exist
; #input: ds:dx - file name
; #output: ax != 0 if exists, ax == 0 if does not exist
file_exists:
    push    si
    cmp     [cs:file_mode], O_NONE
    je      file_exists_mode_ok
    error   ERR_FILE_OPENED
  file_exists_mode_ok:
    call    find_inode
    test    si, si
    jz      file_exists_not_found
    mov     ax, TRUE
    jmp     file_exists_exit
  file_exists_not_found:
    mov     ax, FALSE
  file_exists_exit:
    pop     si
    ret
