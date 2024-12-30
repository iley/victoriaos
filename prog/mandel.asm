; VictoriaOS: mandelbrot's fractal drawing demo program

org 100h
include 'victoria.inc'

jmp     start

        key_esc         equ 01h
        key_down        equ 50h
        key_up          equ 48h
        key_left        equ 4bh
        key_right       equ 4dh
        key_plus        equ 4eh
        key_enter		equ 1ch
        key_minus       equ 4ah
        key_first_scr   equ 47h
        key_show_frame  equ 39h

        frame_step      equ 2
        
        video_seg       equ 0a000h
        colors          equ 255

        screen_x        equ 320
        screen_y        equ 200

        frame_x         equ 64
        frame_y         equ 40

        magic_const     equ 128
        undo_num        equ 10
        undo_rec_size   equ 40

align 2
        tmp             dt ?

        left            dt -2.5
        top             dt -2.0
        x_range         dt 5.0
        y_range         dt 4.0

        first_left      dt -2.5
        first_top       dt -2.0
        first_x_range   dt 5.0
        first_y_range   dt 4.0

;        old_data        dt undo_num*undo_rec_size dup(?)

        re_c            dt ?
        im_c            dt ?
        re_z            dt ?
        im_z            dt ?

        x               dd ?
        y               dd ?
        w               dd ?
        h               dd ?

        scr_width       dd screen_x
        scr_height      dd screen_y

        fx              dw (screen_x-frame_x)/2
        fy              dw (screen_y-frame_y)/2
        tmpi            dw ?
        undo_top        dw ?


        old_vmode       db ?
        frame_visible   db 0ffh


;������஢��� ��אַ㣮���� ������� �࠭� (�⬥砥� 㢥��稢���� �ࠣ����)
;��ࠬ����: x, y - ���न����, w, h - �ਭ� � ����
invert_rect:
        pusha
        pushf
        
        mov     ax, word [y]
        mov     bx, screen_x
        mul     bx
        mov     di, ax
        add     di, word [x]
        ;横� �� ��ப��
        mov     cx, word [h]
    df1_row_loop:
        push    cx

        ;横� �� �⮫�栬
        mov     cx, word [w]
    df1_col_loop:
        mov     al, byte [es:di]
        xor     al, magic_const
        stos    byte [es:di]
        loop    df1_col_loop

        add     di, screen_x
        sub     di, word [w]
        pop     cx
        loop    df1_row_loop

        popf
        popa
        ret

;�⬥��� ������� 楫����. ��ࠬ���� ������ - fx, fy - ���न���� 㣫�, 
;frame_x, frame_y - �ਭ� � ����
draw_frame:
        push    ax
        mov     ax, word [fx]
        mov     word [x], ax
        mov     ax, word [fy]
        mov     word [y], ax
        mov     word [w], frame_x
        mov     word [h], frame_y
        call    invert_rect
        pop     ax
        ret

;������� �᫮ ���権 ��� ����� �窨
;��ࠬ����: x, y - 楫� ���न���� �窨
calc_point:
        push    cx
        finit
        
        ;������뢠�� 楫� ���न���� � ����⢥���
        fild    dword [x]
        fild    dword [scr_width]
        fdivp
        fld     tword [x_range]
        fmulp
        fld     tword [left]
        faddp   ; st0=re(c)
        fstp    tword [re_c]

        fild    dword [y]
        fild    dword [scr_height]
        fdivp
        fld     tword [y_range]
        fmulp
        fld     tword [top]
        faddp   ;st0=im(c)
        fstp    tword [im_c]

        ;����塞 z
        fldz
        fstp    tword [re_z]    ;re_z=0
        fldz
        fstp    tword [im_z]    ;im_z=0

        ;��. 横�
        mov     cl, colors
    cp_loop:
        
        ;�஢�ઠ ��室� �� ��� ࠤ��� 2
        fld     tword [re_z]
        fmul    st0, st0
        fld     tword [im_z]
        fmul    st0, st0
        faddp                   
        fld1
        fadd    st0, st0        ;st0=2.0, st1=|z|^2
        fadd    st0, st0        ;st0=4.0, st1=|z|^2
        fcompp
        fstsw   ax
        sahf
        jb      cp_exit
        
        ;��⠥� ᫥���騩 童� ��᫥����⥫쭮��
        fld     tword [re_z]
        fmul    st0, st0
        fld     tword [im_z]
        fmul    st0, st0
        fsubp
        fld     tword [re_c]
        faddp
        fstp    tword [tmp]     ;tmp=Re(z1)

        fld1
        fadd    st0, st0
        fld     tword [re_z]
        fmulp
        fld     tword [im_z]
        fmulp
        fld     tword [im_c]
        faddp
        fstp    tword [im_z]

        fld     tword [tmp]
        fstp    tword [re_z]

        dec     cl
        jnz     cp_loop
    cp_exit:
        ;�����頥� �᫮ ���権
        mov     al, 0ffh
        sub     al, cl
        pop     cx
        ret

;��㥬 �ࠪ⠫
;��ࠬ����: left, top - ���� ���孨� 㣮�, x_range, y_range - ��������
draw_fractal:         
        mov     ax, video_seg
        mov     es, ax

        mov     di, 0
        mov     dx, 0
    df_col_loop:
        mov     dword [y], 0
        mov     word [y], dx
        mov     cx, 0
    
    df_row_loop:
        mov     dword [x], 0
        mov     word [x], cx
        call    calc_point
        stosb
        inc     cx
        cmp     cx, screen_x
        jb      df_row_loop
        
        inc     dx
        cmp     dx, screen_y
        jb      df_col_loop
        ret

;��࠭���� ��ࠬ��஢ ������ ��। 㢥��祭���
push_data:
        cld
        mov     ax, ds
        mov     es, ax
        cmp     word [undo_top], old_data + undo_rec_size * undo_num
        jb      pd1_no_overflow
        mov     si, old_data + undo_rec_size
        mov     di, old_data
        mov     cx, undo_rec_size * (undo_num)
        rep     movsb
        sub     word [undo_top], undo_rec_size
    pd1_no_overflow:
        mov     di, word [undo_top]
        mov     si, left
        mov     cx, undo_rec_size/2
        rep     movsw
        add     word [undo_top], undo_rec_size
        mov     ax, video_seg
        mov     es, ax
        ret

;������ ��ࠬ��஢
pop_data:
        cld
        mov     ax, ds
        mov     es, ax
        cmp     word [undo_top], old_data
        je      pd2_exit
        mov     si, word [undo_top]
        sub     si, undo_rec_size
        mov     di, left
        mov     cx, undo_rec_size/2
        rep     movsw
        sub     word [undo_top], undo_rec_size
    pd2_exit:
        mov     ax, video_seg
        mov     es, ax
        ret

start:
        ;��࠭塞 �।��騩 ���. ०��
        mov     ah, 0fh
        int     10h
        mov     byte [old_vmode], al

        ;������ ���� ���. ०�� - 320x200, 256 梥⮢
        mov     ax, 0013h
        int     10h

        ;������ es ��� ��אַ� ࠡ��� � ������������
        mov     ax, video_seg
        mov     es, ax

        ;���樠�����㥬 �⥪ undo
        mov     word [undo_top], old_data
        
        ;��㥬 �ࠪ⠫ � ���� ࠧ
        call    draw_fractal
        
        call    draw_frame
scan_kbd:
        ;��ࠡ�⪠ ����������
;        mov     ah, 8
;        int     21h
        mov     ah, 00h
        int     16h

        mov     al, ah

        ;��室
        cmp     al, key_esc
        je      exit

        ;���室 � ०�� ��ᬮ��
        cmp     al, key_show_frame
        jne     not_key_show_frame
        not     byte [frame_visible]
        call    draw_frame
    not_key_show_frame:

        cmp     byte [frame_visible], 0
        je      scan_kbd

        cmp     al, key_left
        jne     not_left
        cmp     word [fx], 0
        je      scan_kbd

        sub     word [fx], frame_step
        
        mov     ax, word [fx]
        add     ax, frame_x
        mov     word [x], ax
        mov     ax, word [fy]
        mov     word [y], ax
        mov     word [w], frame_step
        mov     word [h], frame_y
        call    invert_rect

        mov     ax, word [fx]
        mov     word [x], ax
        call    invert_rect
        jmp     scan_kbd
    not_left:

        ;ᤢ�� ������ �뤥����� ��ࠢ�
        cmp     al, key_right
        jne     not_right
        cmp     word [fx], screen_x-frame_x
        jae     scan_kbd

        mov     ax, word [fx]
        mov     word [x], ax
        mov     ax, word [fy]
        mov     word [y], ax
        mov     word [w], frame_step
        mov     word [h], frame_y
        call    invert_rect

        mov     ax, word [fx]
        add     ax, frame_x
        mov     word [x], ax
        call    invert_rect
        add     word [fx], frame_step
        jmp     scan_kbd
    not_right:

        ;ᤢ�� ������ �뤥����� �����
        cmp     al, key_up
        jne     not_up
        cmp     word [fy], 0
        je      scan_kbd

        sub     word [fy], frame_step

        mov     ax, word [fx]
        mov     word [x], ax
        mov     ax, word [fy]
        mov     word [y], ax
        mov     word [h], frame_step
        mov     word [w], frame_x
        call    invert_rect

        mov     ax, word [fy]
        add     ax, frame_y
        mov     word [y], ax
        call    invert_rect
        jmp     scan_kbd
    not_up:

        ;ᤢ�� ������ �뤥����� ����
        cmp     al, key_down
        jne     not_down
        cmp     word [fy], screen_y-frame_y
        je      scan_kbd

        mov     ax, word [fx]
        mov     word [x], ax
        mov     ax, word [fy]
        mov     word [y], ax
        mov     word [h], frame_step
        mov     word [w], frame_x
        call    invert_rect

        mov     ax, word [fy]
        add     ax, frame_y
        mov     word [y], ax
        call    invert_rect
        add     word [fy], frame_step
        jmp     scan_kbd
    not_down:

        ;㢥��祭��
        cmp     al, key_plus
        je      plus

        cmp		al, key_enter
        je		plus

        jmp		not_plus

    plus:

        ;��࠭塞 ���祭�� ��� ������
        call    push_data

        finit
        ;�����뢠�� ���� ���祭��
        fild    word [fx]
        fild    dword [scr_width]
        fdivp
        fld     tword [x_range]
        fmulp
        fld     tword [left]
        faddp
        fstp    tword [left]

        mov     word [tmpi], frame_x
        fild    word [tmpi]
        fild    word [scr_width]
        fdivp
        fld     tword [x_range]
        fmulp
        fstp    tword [x_range]

        fild    word [fy]
        fild    dword [scr_height]
        fdivp
        fld     tword [y_range]
        fmulp
        fld     tword [top]
        faddp
        fstp    tword [top]

        mov     word [tmpi], frame_y
        fild    word [tmpi]
        fild    word [scr_height]
        fdivp
        fld     tword [y_range]
        fmulp
        fstp    tword [y_range]

        call    draw_fractal
        call    draw_frame
        jmp     scan_kbd
    not_plus:

        ;������ �� 蠣 �����
        cmp     al, key_minus
        jne     not_minus

        cmp     word [undo_top], old_data
        je      scan_kbd
        
        call    pop_data
        call    draw_fractal
        call    draw_frame
        jmp     scan_kbd
    not_minus:

        ;������ � ᠬ�� ��砫�
        cmp     al, key_first_scr
        jne     not_first_scr

        finit
        
        call    push_data
        
        mov     ax, ds
        mov     es, ax
        mov     si, first_left
        mov     di, left
        mov     cx, undo_rec_size / 2
        rep     movsw
        mov     ax, video_seg
        mov     es, ax

        call    draw_fractal
        call    draw_frame
    not_first_scr:

        jmp     scan_kbd

exit:
        ;����⠭�������� �।��騩 ०��
        mov     al, byte [old_vmode]
        mov     ah, 0
        int     10h
        ret

old_data:
;-- vim: set filetype=fasm:
