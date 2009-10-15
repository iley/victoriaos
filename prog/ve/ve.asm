; VictoriaOS: Victoria Editor (VE)
; Copyright Nickolay Kudasov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

org 100h

    include 'victoria.inc'

    jmp     start

    ; key codes
    KEY_LEFT            equ 75
    KEY_RIGHT           equ 77
    KEY_UP              equ 72
    KEY_DOWN            equ 80

    KEY_F1              equ 59
    KEY_F2              equ 60
    KEY_F3              equ 61
    KEY_F4              equ 62
    KEY_F5              equ 63
    KEY_F6              equ 64
    KEY_F7              equ 65
    KEY_F8              equ 66
    KEY_F9              equ 67
    KEY_F10             equ 68

    KEY_HOME            equ 71
    KEY_END             equ 79

    KEY_CTRL_HOME       equ 119
    KEY_CTRL_END        equ 117

    KEY_PAGEUP          equ 73
    KEY_PAGEDOWN        equ 81

    KEY_TAB             equ 

    KEY_INSERT          equ 82
    KEY_DELETE          equ 83
    KEY_BACKSPACE       equ 14

    TAB_CODE            equ 15
    ESCAPE_CODE         equ 27
    RETURN_CODE         equ EOLN

    ; text attributes
    cl_bright           equ 10h
    cl_blink            equ 80h

    cl_black            equ 00h
    cl_blue             equ 01h
    cl_green            equ 02h
    cl_cyan             equ 03h
    cl_red              equ 04h
    cl_magenta          equ 05h
    cl_brown            equ 06h
    cl_white            equ 07h

    cl_gray             equ 08h
    cl_bright_blue      equ 09h
    cl_bright_green     equ 0ah
    cl_bright_cyan      equ 0bh
    cl_bright_red       equ 0ch
    cl_bright_magenta   equ 0dh
    cl_yellow           equ 0eh
    cl_bright_white     equ 0fh

    SAVE_OR_NOT_COLOR   equ 40h
    ABOUT_COLOR         equ 50h
    TEXT_COLOR          equ cl_white
    STATUS_COLOR        equ 20h
    DEBUG_COLOR         equ cl_bright_red

    ; screen constants
    SCR_WIDTH           equ 80
    SCR_HEIGHT          equ 24 ; screen height is 25, but last row is a status one

    VID_SEG             equ 0b800h

    ; about message parameters
    RECT_START_ROW      equ 7
    RECT_START_COL      equ 28
    RECT_WIDTH          equ 23
    RECT_HEIGHT         equ 11

    ; save_or_not message parameters
    SAVE_OR_NOT_WIDTH   equ 25
    SAVE_OR_NOT_HEIGHT  equ 5

    file_name           dw  ? ; name of opened file

    vid_pos             dw  ? ; current position in video segment
    current             dw  ? ; current position in buffer
    finish              dw  ? ; position of last symbol in buffer
    line_count          dw  ? ; total count of lines in the text
    scrolled_down       dw  ? ; lines scrolled down

    input_mode          db  ? ; 0 - insert; 1 - overwrite
    graph_mode          db  ? ; 0 - text; 1 - pseudographics
    modified            db  ? ; 0 - saved;  1 - modified
    color               db  ? ; current color

    ; cursor position
    cursor_row          db  ?
    cursor_col          db  ?

                           ;abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
    graph_symbols       db 'รสูดฟฬฮนณอบฒÛผฐฑฺษลหฤศยมปภÞ  Ý              þ   Ü฿  '
    default_name        db 'NONAME', 0

    msg_error           db 'ERROR: Not enough command line parameters', EOLN, 0
    msg_exit            db 'Save changes?(y/n)', EOLN, 0

    msg_about           db 'ษอออออออออออออออออออออป'
                        db 'บVictoria Editor v0.01บ'
                        db 'บ   by Crazy FIZRUK   บ'
                        db 'บ                     บ'
                        db 'บ      Hot Keys:      บ'
                        db 'บ                     บ'
                        db 'บ     F1  - help      บ'
                        db 'บ     F2  - save      บ'
                        db 'บ     F3  - mode      บ'
                        db 'บ     ESC - exit      บ'
                        db 'ศอออออออออออออออออออออผ'

    msg_save_or_not     db 'ษอออออออออออออออออออออออป'
                        db 'บ   File was modified!  บ'
                        db 'บDo you want to save it?บ'
                        db 'บ         (y/n)         บ'
                        db 'ศอออออออออออออออออออออออผ'
                                                  
    extra_buf_size      equ 10                      ; size of extra buffer
    extra_buffer        db  extra_buf_size dup 0    ; extra buffer

start:
    call    init

  main_loop:
    call    show_status_bar
    call    set_cursor_pos

    ; waiting for any key pressed
    xor     ax, ax
    int     16h
    
    cmp     al, ESCAPE_CODE
    jz      exit_start

    cmp     word [current], buf_size
    jnb     skip_ascii

    cmp     al, RETURN_CODE
    jnz     skip_return

    inc     word [line_count]
    call    put_char
    call    clear_row
    call    new_line
    call    scroll_down
    call    insert_indent
    call    clear_row
    call    update_row
    jmp     main_loop
  skip_return:

    cmp     al, 9
    jnz     skip_tabulation
    call    print_tab
  skip_tabulation:

    cmp     al, ' '
    jb      skip_ascii

    cmp     byte [graph_mode], 0
    jz      skip_graph_mode
    call    graph_symbol
  skip_graph_mode:
    call    print_char
    call    put_char
    call    move_next
    call    update_row
  skip_ascii:

    cmp     ah, KEY_LEFT
    jnz     skip_left
    call    move_backward
    jmp     main_loop
  skip_left:

    cmp     ah, KEY_RIGHT
    jnz     skip_right
    call    move_forward
    jmp     main_loop
  skip_right:

    cmp     ah, KEY_UP
    jnz     skip_up
    call    move_up
    jmp     main_loop
  skip_up:

    cmp     ah, KEY_DOWN
    jnz     skip_down
    call    move_down
    jmp     main_loop
  skip_down:

    cmp     ah, KEY_HOME
    jnz     skip_home
    call    move_to_home
    jmp     main_loop
  skip_home:

    cmp     ah, KEY_END
    jnz     skip_end
    call    move_to_end
    jmp     main_loop
  skip_end:

    cmp     ah, KEY_INSERT
    jnz     skip_insert
    call    change_input_mode
    jmp     main_loop
  skip_insert:

    cmp     ah, KEY_DELETE
    jnz     skip_delete
    call    delete_char
    jmp     main_loop
  skip_delete:

    cmp     ah, KEY_BACKSPACE
    jnz     skip_backspace
    call    delete_prev_char
    jmp     main_loop
  skip_backspace:

    cmp     ah, KEY_F1
    jnz     skip_f1
    call    show_about_msg
    jmp     main_loop
  skip_f1:

    cmp     ah, KEY_F2
    jnz     skip_f2
    call    save_file
    jmp     main_loop
  skip_f2:

    cmp     ah, KEY_F3
    jnz     skip_f3
    not     byte [graph_mode]
    jmp     main_loop
  skip_f3:

    cmp     ah, KEY_CTRL_HOME
    jnz     skip_ctrl_home
    call    go_home
    jmp     main_loop
  skip_ctrl_home:

    cmp     ah, KEY_CTRL_END
    jnz     skip_ctrl_end
    call    go_end
    jmp     main_loop
  skip_ctrl_end:

    cmp     ah, KEY_PAGEUP
    jnz     skip_pageup
    call    page_up
    jmp     main_loop
  skip_pageup:

    cmp     ah, KEY_PAGEDOWN
    jnz     skip_pagedown
    call    page_down
    jmp     main_loop
  skip_pagedown:

    jmp     main_loop
    
  exit_start:

    ; actions before exit

    ; ask for saving if modified
    cmp     byte [modified], 1
    jnz     skip_quit_ask
    call    show_save_or_not_msg

    ; waiting for 'y' or 'n'
  wait_loop:
    mov     ah, 0h
    int     16h

    cmp     al, ESCAPE_CODE
    jnz     skip_return_to_main_loop
    call    clear_screen
    call    update_screen
    jmp     main_loop
  skip_return_to_main_loop:

    cmp     al, 'y'
    jnz     skip_yes
    call    save_file
    jmp     skip_quit_ask
  skip_yes:

    cmp     al, 'n'
    jnz     skip_no
    jmp     skip_quit_ask
  skip_no:

    jmp     wait_loop
  skip_quit_ask:

    ; clearing the screen
    push    VID_SEG
    pop     es

    xor     dx, dx
    mov     al, ' '
    mov     ah, TEXT_COLOR
    mov     cx, 80*25
    rep     stosw

    ; moving cursor at left top position
    xor     dx, dx
    xor     bh, bh
    mov     ah, 02h
    int     10h

    ; setting cursor size
    mov     ah, 01h
    mov     cx, 1e1fh
    xor     bh, bh
    mov     bl, TEXT_COLOR
    int     10h

    ret

; #proc change_input_mode
change_input_mode:
    push    ax bx cx

    cmp     byte [input_mode], 0
    jz      skip_toinsert_mode
    ; to insert mode
    mov     byte [input_mode], 0
    mov     ah, 01h
    mov     cx, 1e1fh
    xor     bh, bh
    mov     bl, TEXT_COLOR
    int     10h
    jmp     exit_change_input_mode
  skip_toinsert_mode:
    ; to overwrite mode
    mov     byte [input_mode], 1
    mov     ah, 01h
    mov     cx, 001fh
    xor     bh, bh
    mov     bl, TEXT_COLOR
    int     10h
  exit_change_input_mode:
    
    pop     cx bx ax
    ret

; #proc count_line_left
; #output     ax - length of the left part of line
count_line_left:
    push    cx di

    xor     ax, ax

    mov     di, buffer
    add     di, [current]
    mov     al, RETURN_CODE

    mov     cx, [current]

  count_eoln_left_loop:
    test    cx, cx
    jz      exit_count_eoln_left
    dec     di
    cmp     byte [di], RETURN_CODE
    jz      exit_count_eoln_left
    loop     count_eoln_left_loop

  exit_count_eoln_left:
    mov     ax, [current]
    sub     ax, cx
    pop     di cx
    ret

; #proc count_line_right:   counting number of characters up to the end
;                           in current line since current character
;                           result is stored in AX, in [current] must be stored
;                           position of the ANY character in line
; #output   ax - number of characters in line after [current]
count_line_right:
    push    cx di

    xor     ax, ax

    mov     di, buffer
    add     di, [current]
    mov     al, RETURN_CODE

    mov     cx, [finish]
    sub     cx, [current]
    push    cx

  count_line_right_loop:
    test    cx, cx
    jz      exit_count_line_right
    cmp     byte [di], RETURN_CODE
    jz      exit_count_line_right
    inc     di
    loop    count_line_right_loop

  exit_count_line_right:
    pop     ax
    sub     ax, cx
    pop     di cx
    ret

; #proc count_lines:    count lines in the whole text
;                       result is moved to [line_count]
count_lines:
    push    ax cx si

    mov     si, buffer
    mov     cx, [finish]

    mov     word [line_count], 1

    cld
    test    cx, cx
    jz      exit_count_lines

  count_lines_loop:
    lodsb
    cmp     al, RETURN_CODE
    jnz     skip_add_line
    inc     word [line_count]
  skip_add_line:
    loop    count_lines_loop
    
  exit_count_lines:
    pop     si cx ax
    ret

; #proc clear_row: from current position up to the end
clear_row:
    push    ax cx di es

    push    VID_SEG
    pop     es

    mov     di, [vid_pos]

    xor     cx, cx
    mov     cl, SCR_WIDTH
    sub     cl, [cursor_col]
    
    mov     ah, [color]
    mov     al, ' '
    cld
    rep     stosw

    pop     es di cx ax
    ret

; #proc clear_screen
clear_screen:
    push    ax cx di es

    push    VID_SEG
    pop     es
    
    mov     ah, TEXT_COLOR
    mov     al, ' '
    xor     di, di
    cld
    mov     cx, SCR_WIDTH*SCR_HEIGHT
    rep     stosw

    pop     es di cx ax
    ret

; #proc delete_char
delete_char:
    push    ax si

    mov     ax, [current]
    inc     ax
    cmp     [finish], ax
    jb      exit_delete_char

    mov     byte [modified], 1

    mov     si, buffer
    add     si, [current]
    cmp     byte [si], RETURN_CODE
    jnz     skip_delete_eoln
    dec     word [line_count]
  skip_delete_eoln:

    mov     ax, [current]
    inc     ax
    cmp     [finish], ax
    jnz     skip_delete_last
    dec     word [finish]
    call    clear_row
    jmp     exit_delete_char
  skip_delete_last:

    call    shift_buffer_left
    call    clear_screen
    call    update_screen
  exit_delete_char:

    pop     si ax
    ret

; #proc delete_prev_char
delete_prev_char:
    cmp     word [current], 0
    jna     exit_delete_prev_char

    call    move_backward
    call    delete_char
  exit_delete_prev_char:

    ret

; #proc attr_error
error:
    mov     dx, msg_error
    syscall SC_PUTS
    int     51h
    ret

; #proc go_end
go_end:
    push    ax cx

    mov     cx, [line_count]
    xor     ax, ax
    mov     al, [cursor_row]
    add     ax, [scrolled_down]
    sub     cx, ax
    dec     cx

    test    cx, cx
    jz      exit_go_end

  go_end_loop:
    call    move_down
    loop    go_end_loop

    call    move_to_end

  exit_go_end:
    pop     cx ax
    ret

; #proc go_home
go_home:
    push    cx

    call    move_to_home
    xor     ch, ch
    mov     cl, [cursor_row]
    add     cx, [scrolled_down]

    test    cx, cx
    jz      exit_go_home

  go_home_loop:
    call    move_up
    loop    go_home_loop

  exit_go_home:
    pop     cx
    ret

; #proc graph_symbol
; #output ax
graph_symbol:
    push    bx di

    cmp     al, 'A'
    jb      skip_capital
    cmp     al, 'Z'
    ja      skip_capital
    xor     bx, bx
    sub     al, 'A' - 26
    mov     bl, al
    mov     di, graph_symbols
    add     di, bx
    mov     al, [di]
    jmp     exit_graph_symbol
  skip_capital:
    
    cmp     al, 'a'
    jb      skip_smaller
    cmp     al, 'z'
    ja      skip_smaller
    xor     bx, bx
    sub     al, 'a'
    mov     bl, al
    mov     di, graph_symbols
    add     di, bx
    mov     al, [di]
  skip_smaller:

  exit_graph_symbol:
    pop     di bx
    ret

; #proc init_editor
init:
    push    ax dx si

    mov     ax, 0003h
    int     10h

    mov     word [current], 0
    mov     word [vid_pos], 0
    mov     word [scrolled_down], 0

    mov     byte [input_mode], 0
    mov     byte [graph_mode], 0
    mov     byte [modified], 0
    mov     byte [cursor_row], 0
    mov     byte [cursor_col], 0
    mov     byte [color], TEXT_COLOR

    mov     si, 080h
    cld
  init_scan_loop:
    lodsb
    test    al, al
    jz      error
    cmp     al, ' '
    jz      scan_found_init
    jmp     init_scan_loop
  scan_found_init:
   ;si is a start of the file name
    mov     [file_name], si
    mov     dx, si

    syscall SC_FILE_EXISTS
    test    ax, ax
    jz      skip_file_exists
    call    load_file
    call    print_all
    jmp     exit_init
  skip_file_exists:

    ; if file doesn't exist
    mov     word [finish], 0
    mov     word [line_count], 1
                                
  exit_init:

    call    set_cursor_pos

    pop     si dx ax
    ret

; #proc insert_indent
insert_indent:
    push    ax si

    mov     si, buffer - 1
    add     si, [current]
  insert_indent_loop:
    dec     si
    cmp     byte [si], EOLN
    jz      exit_insert_indent_loop
    cmp     si, buffer - 1
    jz      exit_insert_indent_loop
    jmp     insert_indent_loop
  exit_insert_indent_loop:

    inc     si
    cld
  insert_indent_loop2:
    lodsb
    cmp     al, ' '
    jnz     exit_insert_indent_loop2
    call    print_char
    call    put_char
    call    move_next
    call    update_row
    jmp     insert_indent_loop2
  exit_insert_indent_loop2:

    pop     si ax
    ret

; #proc load_file: loading file to buffer
load_file:
    push    ax cx dx

    mov     dx, [file_name]
    mov     al, O_READ
    syscall SC_OPEN_FILE
    
    mov     word [finish], cx
    mov     word [line_count], 0

    mov     dx, buffer
    syscall SC_READ

    call    count_lines

    syscall SC_CLOSE_FILE

    pop     dx cx ax
    ret

; #proc move_backward
move_backward:
    push    ax si

    cmp     word [current], 0
    jz      exit_move_backward

    dec     word [vid_pos]
    dec     word [vid_pos]
    
    dec     word [current]
    mov     si, buffer
    add     si, [current]
    
    cmp     byte [si], RETURN_CODE
    jnz     skip_return_move_backward

    call    count_line_left

    cmp     byte [cursor_row], 0
    ja      skip_move_backward_scroll
    call    scroll_screen_down
    mov     [cursor_col], al
    inc     ax
    shl     ax, 1
    add     [vid_pos], ax

    call    move_to_home
    call    clear_row
    call    update_row
    call    move_to_end
    dec     word [scrolled_down]

    jmp     exit_move_backward
  skip_move_backward_scroll:

    dec     byte [cursor_row]
    mov     [cursor_col], al

    xor     ah, ah
    mov     al, SCR_WIDTH-1
    sub     al, [cursor_col]
    shl     ax, 1
    sub     [vid_pos], ax

    jmp     exit_move_backward
  skip_return_move_backward:

    dec     byte [cursor_col]
  exit_move_backward:

    mov     ah, 02h
    int     16h

    pop     si ax
    ret

; #proc move_down
move_down:
    push    ax cx

    mov     ax, [line_count]
    sub     ax, [scrolled_down]
    cmp     byte [cursor_row], al
    jnb     exit_move_down

    mov     al, [cursor_col]
    call    move_to_end
    call    move_forward
    call    move_to_end
    cmp     [cursor_col], al
    jna     exit_move_down
    xor     cx, cx
    mov     cl, [cursor_col]
    sub     cl, al
    mov     [cursor_col], al
    call    set_cursor_pos
    sub     word [current], cx
    shl     cx, 1
    sub     word [vid_pos], cx
  exit_move_down:

    pop     cx ax
    ret

; #proc move_forward
move_forward:
    push    ax si

    mov     ax, [finish]
    cmp     word [current], ax
    jnb     exit_move_forward

    mov     si, buffer
    add     si, [current]
    
    cmp     byte [si], RETURN_CODE
    jnz     skip_return_move_forward

    call    new_line
    inc     word [current]
    call    clear_row
    call    update_row
    jmp     exit_move_forward
  skip_return_move_forward:

    inc     word [vid_pos]
    inc     word [vid_pos]

    inc     byte [cursor_col]

    inc     word [current]
  exit_move_forward:

    mov     ah, 02h
    int     16h

    pop     si ax
    ret

; #proc move_next
move_next:
    cmp     byte [cursor_col], SCR_WIDTH-1
    jnb     exit_move_next
    inc     byte [cursor_col]
  exit_move_next:
    ret

; #proc move_to_end
move_to_end:
    push    ax si

    call    count_line_right
    
    add     [current], ax
    add     [cursor_col], al
    shl     ax, 1
    add     [vid_pos], ax

    pop     si ax
    ret

; #proc move_to_home
move_to_home:
    push    ax

    xor     ax, ax
    mov     al, [cursor_col]
    sub     [current], ax
    shl     ax, 1
    sub     [vid_pos], ax

    mov     byte [cursor_col], 0

    pop     ax
    ret

; #proc move_up
move_up:
    push    ax cx

    mov     al, [cursor_row]
    xor     ah, ah
    add     ax, [scrolled_down]
    cmp     ax, 0
    jz      exit_move_up

    mov     al, [cursor_col]
    call    move_to_home
    call    move_backward
    cmp     [cursor_col], al
    jna     exit_move_up
    xor     cx, cx
    mov     cl, [cursor_col]
    sub     cl, al
    mov     [cursor_col], al

    sub     word [current], cx
    shl     cx, 1
    sub     word [vid_pos], cx
  exit_move_up:
    pop     cx ax
    ret

; #proc new_line
new_line:
    push    ax

    cmp     byte [cursor_row], SCR_HEIGHT-1
    jb      skip_new_line_scroll
    xor     ah, ah
    mov     al, [cursor_col]
    shl     ax, 1
    sub     [vid_pos], ax
    call    scroll_screen_up
    inc     word [scrolled_down]
    jmp     exit_new_line
  skip_new_line_scroll:

    xor     ah, ah
    mov     al, SCR_WIDTH
    sub     al, [cursor_col]
    
    shl     ax, 1
    add     [vid_pos], ax

    inc     byte [cursor_row]
    
  exit_new_line:
    mov     byte [cursor_col], 0

    pop     ax
    ret

; #proc page_down
page_down:
    push    ax bx cx dx

    mov     dl, [cursor_col]

    xor     ah, ah
    mov     al, [cursor_row]
 
    mov     bx, [line_count]
    sub     bx, [scrolled_down]
    sub     bx, ax
    dec     bx

    cmp     bx, SCR_HEIGHT
    jnb     skip_page_down_go_end
    call    go_end
    jmp     exit_page_down
  skip_page_down_go_end:
    
    mov     cx, SCR_HEIGHT*2-1
    sub     cx, ax

    cmp     bx, cx
    jnb     skip_page_down_not_full

    test    bx, bx
    jz      exit_page_down

    mov     cx, bx
  page_down_loop3:
    call    move_down
    loop    page_down_loop3

    mov     cx, bx
    sub     cx, SCR_HEIGHT

    test    cx, cx
    jz      exit_page_down

  page_down_loop4:
    call    move_up
    loop    page_down_loop4
    jmp     exit_page_down
  skip_page_down_not_full:
    
  page_down_loop1:
    call    move_down
    loop    page_down_loop1

    mov     cx, SCR_HEIGHT-1
    sub     cx, ax

    test    cx, cx
    jz      exit_page_down

  page_down_loop2:
    call    move_up
    loop    page_down_loop2

  exit_page_down:    
    call    move_to_end
    cmp     [cursor_col], dl
    jna     skip_page_down_return_cursor
    xor     ah, ah
    mov     al, [cursor_col]
    sub     al, dl
    sub     [current], ax
    shl     ax, 1
    sub     [vid_pos], ax
    mov     [cursor_col], dl
  skip_page_down_return_cursor:

    pop     dx cx bx ax
    ret

; #proc page_up
page_up:
    push    ax bx cx dx

    mov     dl, [cursor_col]

    xor     ah, ah
    mov     al, [cursor_row]

    mov     bx, [scrolled_down]
    add     bx, ax

    cmp     bx, SCR_HEIGHT
    jnb     skip_page_up_go_home
    call    go_home
    jmp     exit_page_up
  skip_page_up_go_home:
    
    mov     cx, SCR_HEIGHT
    add     cx, ax

    cmp     bx, cx
    jnb     skip_page_up_not_full

    test    bx, bx
    jz      exit_page_up

    mov     cx, bx
  page_up_loop3:
    call    move_up
    loop    page_up_loop3

    mov     cx, bx
    sub     cx, SCR_HEIGHT

    test    cx, cx
    jz      exit_page_up

  page_up_loop4:
    call    move_down
    loop    page_up_loop4
    jmp     exit_page_up
  skip_page_up_not_full:
    
  page_up_loop1:
    call    move_up
    loop    page_up_loop1

    mov     cx, ax

    test    cx, cx
    jz      exit_page_up

  page_up_loop2:
    call    move_down
    loop    page_up_loop2
    
  exit_page_up:
    call    move_to_end
    cmp     [cursor_col], dl
    jna     skip_page_up_return_cursor
    xor     ah, ah
    mov     al, [cursor_col]
    sub     al, dl
    sub     [current], ax
    shl     ax, 1
    sub     [vid_pos], ax
    mov     [cursor_col], dl
  skip_page_up_return_cursor:

    pop     dx cx bx ax
    ret

; #proc print_all
print_all:
    push    cx

    mov     cx, [line_count]
    cmp     cx, SCR_HEIGHT
    jna     skip_change_counter
    mov     cx, SCR_HEIGHT
  skip_change_counter:

  print_all_loop:
    call    update_row

    cmp     cx, 1
    jz      exit_print_all_loop
    call    move_down
    dec     cx
    jmp     print_all_loop

  exit_print_all_loop:
    mov     byte [cursor_row], 0
    mov     byte [cursor_col], 0
    mov     word [vid_pos], 0
    mov     word [current], 0
    
  exit_print_all:
    pop     cx
    ret

; #proc print_char
; #input AL - character
print_char:
    push    ax di es

    push    VID_SEG
    pop     es

    mov     di, [vid_pos]
    mov     ah, [color]
    stosw

    inc     word [vid_pos]
    inc     word [vid_pos]

    pop     es di ax
    ret

; #proc print_num
; #input AX - number
print_num:
    push    ax bx cx si di

    push    ax
    ; clear extra buffer
    mov     di, extra_buffer
    xor     al, al
    cld
    mov     cx, extra_buf_size
    rep     stosb
    pop     ax

    mov     bl, 10 ; divisor
    mov     di, extra_buffer+extra_buf_size-1 ; last element in extra buffer
    std
  print_num_loop1:
    div     bl
    xchg    ah, al
    stosb
    xchg    ah, al
    xor     ah, ah
    test    ax, ax
    jnz     print_num_loop1

    ; skip zero in the beginning of number
    mov     di, extra_buffer
    xor     al, al
    mov     cx, extra_buf_size
    cld
    repe    scasb

    inc     cx
    dec     di

    ; printing number
    mov     si, di
    cld
  print_num_loop2:
    lodsb
    add     al, '0'
    call    print_char
    loop    print_num_loop2
    
    pop     di si cx bx ax
    ret

; #proc print_tab
print_tab:
    push    ax

    mov     al, ' '
  print_tab_loop:
    call    print_char
    call    put_char
    call    move_next
    call    update_row
    test    byte [cursor_col], 3
    jnz     print_tab_loop

    pop     ax
    ret

; #proc put_char
; #input AL - character
put_char:
    push    di

    mov     byte [modified], 1

    mov     di, buffer
    add     di, [current]

    cmp     byte [di], RETURN_CODE
    jz      shift_buffer_any_way
    cmp     byte [input_mode], 1
    jz      skip_shifting_buffer
  shift_buffer_any_way:
    call    shift_buffer_right
  skip_shifting_buffer:

    stosb
    inc     word [current]

    mov     di, [current]
    cmp     di, [finish]
    jna     skip_update_finish
    mov     [finish], di
  skip_update_finish:


    pop     di
    ret

;!! for VICTORIA only
; #proc save_file
save_file:
    push    ax cx dx

    mov     al, O_WRITE
    mov     dx, [file_name]
    syscall SC_OPEN_FILE

    mov     dx, buffer
    mov     cx, [finish]
    syscall SC_WRITE

    syscall SC_CLOSE_FILE

    mov     byte [modified], 0

    pop     dx cx ax
    ret

; #proc set_cursor_pos
;    [cursor_row] - row
;    [cursor_col] - colomn
set_cursor_pos:
    push    ax bx dx

    mov     dh, [cursor_row]
    mov     dl, [cursor_col]
    mov     ah, 02h
    xor     bh, bh
    int     10h

    pop     dx bx ax
    ret

; #proc scroll_down
scroll_down:
    pusha
    push    ds es

    cmp     byte [cursor_row], SCR_HEIGHT-1
    jnb     exit_scroll_down

    xor     ah, ah
    mov     al, SCR_HEIGHT-1
    sub     al, [cursor_row]
    mov     bl, SCR_WIDTH
    mul     bl
    mov     cx, ax

    test    cx, cx
    jz      exit_scroll_down

    mov     si, [vid_pos]
    add     si, cx
    add     si, cx
    dec     si
    dec     si
    mov     di, si
    add     di, SCR_WIDTH*2

    push    VID_SEG
    push    VID_SEG
    pop     es
    pop     ds

    std
    rep     movsw

  exit_scroll_down:

    pop     es ds
    popa
    ret

; #proc scroll_up
scroll_up:
    pusha
    push    ds es

    cmp     byte [cursor_row], SCR_HEIGHT-1
    jnb     exit_scroll_up

    xor     ah, ah
    mov     al, SCR_HEIGHT-1
    sub     al, [cursor_row]
    mov     bl, SCR_WIDTH
    mul     bl
    mov     cx, ax

    test    cx, cx
    jz      exit_scroll_up

    mov     di, [vid_pos]
    mov     si, di
    add     si, SCR_WIDTH*2


    push    VID_SEG
    push    VID_SEG
    pop     es
    pop     ds

    cld
    rep     movsw

  exit_scroll_up:

    pop     es ds
    popa
    ret

; #proc scroll_screen_down
scroll_screen_down:
    pusha
    push    ds es

    mov     ax, SCR_HEIGHT-1
    mov     bl, SCR_WIDTH
    mul     bl
    mov     cx, ax

    mov     si, 0
    add     si, cx
    add     si, cx
    dec     si
    dec     si
    mov     di, si
    add     di, SCR_WIDTH*2

    push    VID_SEG
    push    VID_SEG
    pop     es
    pop     ds

    std
    rep     movsw

    pop     es ds
    popa
    ret

; #proc scroll_screen_up
scroll_screen_up:
    pusha
    push    ds es

    mov     ax, SCR_HEIGHT-1
    mov     bl, SCR_WIDTH
    mul     bl
    mov     cx, ax

    mov     di, 0
    mov     si, SCR_WIDTH*2

    push    VID_SEG
    push    VID_SEG
    pop     es
    pop     ds

    cld
    rep     movsw

    pop     es ds
    popa
    ret

; #proc shift_buffer_left: shift buffer left from [current] for one character
shift_buffer_left:
    push    di si cx

    mov     si, buffer
    add     si, [current]
    mov     di, si
    inc     si
    mov     cx, [finish]
    sub     cx, [current]
    dec     cx

    test    cx, cx
    jz      exit_shift_buffer_left

    cld
    rep     movsb
    dec     word [finish]
  
  exit_shift_buffer_left:
    pop     cx si di
    ret

; #proc shift_buffer_right: shift buffer right from [current] for one character
shift_buffer_right:
    push    di si cx

    mov     si, buffer
    add     si, [finish]
    mov     di, si
    dec     si
    mov     cx, [finish]
    sub     cx, [current]

    cmp     si, buffer+buf_size-1
    jnz     skip_skip_last_ch
    dec     si
    dec     di
    dec     cx
  skip_skip_last_ch:

    test    cx, cx
    jz      skip_shift_buffer_right_loop
    std
    rep     movsb
  skip_shift_buffer_right_loop:
    inc     word [finish]

    pop     cx si di
    ret

; #proc show_about_msg
show_about_msg:
    push    ax bx cx dx si

    mov     dx, [vid_pos]
    mov     bl, [color]

    push    bx dx

    mov     si, msg_about
    cld

    mov     byte [color], ABOUT_COLOR
    mov     bx, RECT_HEIGHT
  show_about_msg_ver_loop:
    mov     ax, RECT_START_ROW+RECT_HEIGHT
    sub     ax, bx
    mov     dl, 2*SCR_WIDTH
    mul     dl
    add     ax, 2*RECT_START_COL
    mov     [vid_pos], ax

    mov     cx, RECT_WIDTH
  show_about_msg_hor_loop:
    lodsb
    call    print_char
    loop    show_about_msg_hor_loop
    
    dec     bx
    jnz     show_about_msg_ver_loop

    pop     dx bx

    mov     [vid_pos], dx
    mov     [color], bl

    mov     ah, 0h
    int     16h

    call    clear_screen
    call    update_screen
    
    pop     si dx cx bx ax
    ret

; #proc show_save_or_not_msg
show_save_or_not_msg:
    push    ax bx cx dx si

    mov     dx, [vid_pos]
    mov     bl, [color]

    push    bx dx

    mov     si, msg_save_or_not
    cld

    mov     byte [color], SAVE_OR_NOT_COLOR
    mov     bx, SAVE_OR_NOT_HEIGHT
  show_save_or_not_msg_ver_loop:
    mov     ax, RECT_START_ROW+SAVE_OR_NOT_HEIGHT
    sub     ax, bx
    mov     dl, 2*SCR_WIDTH
    mul     dl
    add     ax, 2*RECT_START_COL
    mov     [vid_pos], ax

    mov     cx, SAVE_OR_NOT_WIDTH
  show_save_or_not_msg_hor_loop:
    lodsb
    call    print_char
    loop    show_save_or_not_msg_hor_loop
    
    dec     bx
    jnz     show_save_or_not_msg_ver_loop

    pop     dx bx

    mov     [vid_pos], dx
    mov     [color], bl

    pop     si dx cx bx ax
    ret

; #proc show_status_bar
show_status_bar:
    push    ax bx dx si
    mov     dx, [vid_pos]
    mov     bl, [color]

    mov     byte [color], STATUS_COLOR
    mov     word [vid_pos], 2*SCR_HEIGHT*SCR_WIDTH

    call    clear_row

    ; show file name
    cld
    mov     si, [file_name]
  show_filename_loop:
    lodsb
    test    al, al
    jz      exit_show_filename_loop
    call    print_char
    jmp     show_filename_loop
  exit_show_filename_loop:
    cmp     byte [modified], 1
    jnz     skip_show_modified
    mov     al, '*'
    call    print_char
  skip_show_modified:

    mov     word [vid_pos], 2*(SCR_HEIGHT*SCR_WIDTH+12)
    mov     al, 'l'
    call    print_char
    mov     al, 'i'
    call    print_char
    mov     al, 'n'
    call    print_char
    mov     al, 'e'
    call    print_char
    mov     al, ' '
    call    print_char

    xor     ah, ah
    mov     al, [cursor_row]
    add     ax, [scrolled_down]
    inc     ax
    call    print_num

    mov     al, '/'
    call    print_char

    mov     ax, [line_count]
    call    print_num

    mov     word [vid_pos], 2*(SCR_HEIGHT*SCR_WIDTH+27)

    mov     al, 'c'
    call    print_char
    mov     al, 'o'
    call    print_char
    mov     al, 'l'
    call    print_char
    mov     al, ' '
    call    print_char

    xor     ah, ah
    mov     al, [cursor_col]
    inc     al
    call    print_num

    mov     word [vid_pos], 2*(SCR_HEIGHT*SCR_WIDTH+42)
 
    mov     al, 's'
    call    print_char
    mov     al, 'i'
    call    print_char
    mov     al, 'z'
    call    print_char
    mov     al, 'e'
    call    print_char
    mov     al, ' '
    call    print_char

    mov     ax, [finish]
    call    print_num

    mov     word [vid_pos], 2*(SCR_HEIGHT*SCR_WIDTH+57)

    cmp     byte [graph_mode], 0
    jnz      skip_text_mode_indicator
    mov     al, 't'
    call    print_char
    mov     al, 'e'
    call    print_char
    mov     al, 'x'
    call    print_char
    mov     al, 't'
    call    print_char
    mov     al, ' '
    call    print_char
    jmp     skip_graph_mode_indicator
  skip_text_mode_indicator:
    mov     al, 'g'
    call    print_char
    mov     al, 'r'
    call    print_char
    mov     al, 'a'
    call    print_char
    mov     al, 'p'
    call    print_char
    mov     al, 'h'
    call    print_char
  skip_graph_mode_indicator:
  
    mov     [color], bl
    mov     [vid_pos], dx
    pop     si dx bx ax
    ret

; #proc update_row: from current position up to the end
update_row:
    push    ax bx cx si

    mov     ax, [vid_pos]
    push    ax


    mov     si, buffer
    add     si, [current]

    xor     ch, ch
    mov     cl, SCR_WIDTH
    sub     cl, [cursor_col]

    mov     bx, [finish]
    sub     bx, [current]

    cmp     cx, bx
    jb      skip_mov_cx_bx
    mov     cx, bx
    test    cx, cx
    jz      exit_update_row
  skip_mov_cx_bx:

    cld
  update_row_loop:
    lodsb
    cmp     al, RETURN_CODE
    jz      exit_update_row
    call    print_char
    loop    update_row_loop

  exit_update_row:
    pop     ax
    mov     [vid_pos], ax

    pop     si cx bx ax
    ret

; #proc update_screen
update_screen:
    push    ax bx cx dx

    mov     ax, [vid_pos]
    mov     bx, [current]
    mov     dh, [cursor_row]
    mov     dl, [cursor_col]

    xor     ch, ch
    mov     cl, [cursor_row]

    test    cx, cx
    jz      skip_update_screen_loop1
  update_screen_loop1:
    call    move_up
    loop    update_screen_loop1
  skip_update_screen_loop1:
    
    call    move_to_home
    call    print_all

    mov     [vid_pos], ax
    mov     [current], bx
    mov     [cursor_row], dh
    mov     [cursor_col], dl

    pop     dx cx bx ax
    ret

    buf_size    = 0fff8h-$-256
    buffer      db buf_size dup (?)
;-- vim: set filetype=fasm:
