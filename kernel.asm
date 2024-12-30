; VictoriaOS: kernel

org 8000h
jmp start

    include 'macro/struct.inc'

    include 'proc_table.inc'
    include 'const.inc'
    include 'errors.inc'
    include 'string.inc'
    include 'fs.inc'
    include 'int.inc'
    include 'memory.inc'
    include 'exec.inc'

    text_attr   db  07h

; #proc main
; #output bx
start:
    push    si
    push    ax
    mov     al, ah
    xor     ah, ah
    mov     si, proc_table
    shl     ax, 1
    add     si, ax

	;check, if program's segment is 0000h, then it is loader
	mov		ax, ss
	test	ax, ax
	jnz		not_loader
	mov		ax, EM_SHOW
	jmp		got_mode
  not_loader:
    mov     ax, [ss:PSP_ERR_MODE]
  got_mode:

    mov     [cs:err_mode], ax
    mov     [cs:last_error], ERR_NONE
    mov     ax, sp
    mov     [cs:sp_backup], ax
    pop     ax
    call    word[cs:si]
    
  int_exit:
    mov     bx, [cs:last_error]
    cmp     bx, ERR_NONE
    je      int_no_errors

    push    dx

    test    word[cs:err_mode], EM_SHOW
    jz      int_not_print_error
    ;print error message
    push    ds

    push    cs
    pop     ds
    mov     dx, msg_error   ;display 'ERROR:' message
    call    puts
    call    get_err_msg
    call    puts

    pop     ds
  int_not_print_error:
    
    test    word[cs:err_mode], EM_TERMINATE
    jz      int_not_terminate
    jmp     terminate_handler
  int_not_terminate:

    pop     dx
  int_no_errors:
    pop     si
    iret

;================================================
; #proc get OS version info
; #output: ds:dx - ASCIIZ info, ah - major ver. number, al - release number
get_ver:
    push    dx si di ds es

    push    ds
    pop     es
    
    push    cs
    pop     ds

    mov     si, ver_info
    mov     ax, dx
    mov     di, ax
    call    strcpy
    mov     ah, VER_MAJOR
    mov     al, VER_RELEASE

    pop     es ds di si dx
    ret

;================================================
; #proc
init_screen:
    push    ax bx cx dx
 
    ;set screen mode 80x25
    mov     ah, 00h
    mov     al, DEF_VIDEO_MODE
    int     10h

    ;clear screen
;    xor     cx, cx  ; left=0 & up=0
;    mov     dh, SCR_HEIGHT-1
;    mov     dl, SCR_WIDTH-1
;    mov     ax, 0600h
;    int     10h
    
    ;set cursor position to (0,0)
    xor     dx, dx 
    mov     ah, 02h
    mov     bh, 00h
    int     10h

;    mov     cx, 0e1fh
;    mov     ah, 01h
;    int     10h

    pop     dx cx bx ax
    ret

;================================================
; #proc initialize kernel
init:
    push    ax es

    call    init_screen 
    ;initialize file system
    call    init_fs

    ;initialize interrupt handlers (divizion by zero, reboot)
    call    init_int

    ;other initialization here...
    
    mov     ax, default
    mov     [cs:proc_table + 0ffh * 2], ax
    
    pop     es ax
    ret

;================================================
; #proc scroll screen up 1 line
scroll_up:
    push    ax bx cx dx
    mov     ax, 0601h
    xor     cx, cx
    mov     bh, [cs:text_attr]
    mov     dh, SCR_HEIGHT-1
    mov     dl, SCR_WIDTH-1
    int     10h
    pop     dx cx bx ax
    ret

;================================================
; #proc move cursor down
move_cursor_down:
    push    ax bx dx
    
    call    get_cursor_pos
    cmp     dh, SCR_HEIGHT-1
    jb      move_cursor_down_no_scroll
    call    scroll_up
    jmp     move_cursor_down_exit
  move_cursor_down_no_scroll:
    inc     dh
  move_cursor_down_exit:
    call    update_cursor

    pop     dx bx ax
    ret

;================================================
; #proc move cursor right
move_cursor_right:
    push    ax bx dx

    call    get_cursor_pos
    cmp     dl, SCR_WIDTH-1
    jb      move_cursor_right_no_new_line

    mov     dl, 0

    ;set cursor row
    cmp     dh, SCR_HEIGHT-1
    jb      move_cursor_right_no_scroll
    call    scroll_up
    jmp     move_cursor_right_update
  move_cursor_right_no_scroll:
    inc     dh
  move_cursor_right_update:
    
    call    update_cursor
    jmp     move_cursor_right_exit

  move_cursor_right_no_new_line:
    inc     dl
  move_cursor_right_exit:
    call    update_cursor

    pop     dx bx ax
    ret

;================================================
; #proc update cursor position with cursor_row and cursor_col
; #input: dh - cursor row, dl - cursor col
update_cursor:
    push    ax bx
    mov     ah, 02h
    mov     bh, 00h
    int     10h
    pop     bx ax
    ret

;================================================
; #proc print character with BIOS function
print_char:
    push    ax bx cx
    mov     ah, 09h
    mov     cx, 1
    mov     bh, 0
    mov     bl, [cs:text_attr]
    int     10h
    pop     cx bx ax
    ret

;================================================
; #proc get cursor position
; #output: dh - cursor row, dl - cursor col
get_cursor_pos:
    push    ax bx cx
    ;get cursor positoion
    mov     ah, 03h
    mov     bh, 00h
    int     10h

    pop     cx bx ax
    ret

;================================================
; #proc character output
; #input: al - ascii character
putc:
    push    ax bx cx dx

    call    get_cursor_pos
    
    cmp     al, EOLN
    jne     putc_no_eoln
    mov     dl, 0
    call    update_cursor
    call    move_cursor_down
    jmp     putc_exit
  putc_no_eoln:

    cmp     al, BACKSP
    jne     putc_no_back
    cmp     dl, 0
    je      putc_exit
    dec     dl
    call    update_cursor
    mov     al, ' '
    call    print_char
    jmp     putc_exit
  putc_no_back:

    cmp     al, 10
    jne     putc_no_lf
    mov     dl, 0
    call    update_cursor
    jmp     putc_exit
  putc_no_lf:

    cmp     al, TAB
    jne     putc_no_tab
    ;!!TODO: TABS

    jmp     putc_exit
  putc_no_tab:

    call    print_char
    call    move_cursor_right

  putc_exit:
    
    pop     dx cx bx ax
    ret

;================================================
; #proc ASCIIZ string output
; #input: ds : dx - asciiz string
puts:
    push    ax si
    pushf
    
    mov     si, dx
    cld
  puts_loop:
    lodsb
    test    al, al
    jz      puts_exit
    call    putc
    jmp     puts_loop

  puts_exit:
    popf
    pop     si ax
    ret

;================================================
; #proc ASCII char input
; #output: al - ascii char, ah - scan code
getc:
    xor     ah, ah
    int     16h

    cmp     al, EOLN
    je      getc_put

    cmp     al, FIRST_KBD_CHAR
    jb      getc_exit
  getc_put:
    call    putc
  getc_exit:    
    ret

;================================================
; #ASCIIZ string input
; #input: cx - max. string lenght, ds : dx - buffer
gets:
    push    ax cx di es
    pushf
        
    mov     di, dx
    push    ds
    pop     es

    cld

  gets_loop:
    test    cx, cx
    jz      gets_exit

  gets_getc:
    call    getc

    cmp     al, 0
    je      gets_getc

    cmp     al, TAB
    je      gets_getc

    cmp     al, BACKSP
    jne     not_back

    cmp     di, dx
    jbe     gets_getc

    dec     di
    
    call    putc
    jmp     gets_loop
  not_back:

    cmp     al, EOLN
    je      gets_exit

    cmp     al, 32
    jb      gets_getc

    stosb
    jmp     gets_loop
  gets_exit:
    xor     al, al
    stosb

    popf
    pop     es di cx ax
    ret

;================================================
; #proc set text attribute
; #input: al - text attribute
set_text_attr:
    mov     [cs:text_attr], al
    ret

;================================================
; #proc get text attribute
; #output: al - text attribute
get_text_attr:
    mov     al, [cs:text_attr]
    ret

;================================================
; get error message by code
; input: bx - error code
; output: ds:dx - error message
get_err_msg:
  push  bx si
  push  cs
  pop   ds
  mov   si, err_table
  shl   bx, 1
  add   si, bx
  mov   dx, [cs:si]
  pop   si bx
  ret

;================================================
; set error handling mode
; input: dx - mode (flags are EM_HIDE, EM_SHOW, EM_TERMINATE)
set_err_mode:
  mov   [ss:PSP_ERR_MODE], dx
  ret

;================================================
; #proc empty default procedure
default:
    error   ERR_NO_FUNC
    ret

;================================================
; number of the last error for retuurning in bx
last_error  dw 0
; sp value before calling kernel function (saved for restoring after error)
sp_backup   dw ?

; arrays.inc must be included last
include 'arrays.inc'
;-- vim: set filetype=fasm:
