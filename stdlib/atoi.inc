; VictoriaOS: atoi (C stdlib analog) function
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

;================================================
; #proc atoi
; convert asciiz string to integer
; string/strlwr.inc and strlen.inc should be included
; #input: ds:si - string
; #output: dx:ax - integer, bx = 0 if no error
atoi_sign db 0
atoi_buffer db 16 dup (0)
atoi:
	push	cx si di ds es

	mov		[atoi_sign], 0

	call	strlen
	cmp		cx, 15
	ja		atoi_error

	push	cs
	pop		es
	mov		di, atoi_buffer
	call	strcpy

	mov		si, di
	push	cs
	pop		ds

	call	strlwr

	cmp		byte [si], '-'
	jne		atoi_not_negative
	inc		si
	mov		byte [atoi_sign], 1
  atoi_not_negative:

	call	strlen
	mov		di, si
	add		di, cx
	dec		di		;di = si + strlen(si) - 1
	
	cmp		byte[di], 'h'
	je		atoi_hex

  atoi_dec:
	cmp		byte [si], 0
	je		atoi_error

	mov		cx, 10
	xor		bx, bx
	xor		ax, ax
  atoi_loop:
	mov		bl, [si]
	inc		si
	
	test	bl, bl
	jz		atoi_success

	mov		di, ax
	mov		ax, dx
  	mul		cx
	xchg	ax, di
	mul		cx
	add		dx, di

	cmp		bl, '0'
	jb		atoi_error
	
	cmp		bl, '9'
	ja		atoi_error
	sub		bl, '0'
	add		ax, bx
	jmp		atoi_loop

  atoi_error:
  	xor		bx, bx
	inc		bx
	jmp		atoi_exit

  atoi_success:
  	cmp		byte [atoi_sign], 0
	je		skip_atoi_change_sign
	neg		ax
  skip_atoi_change_sign:
	xor		bx,bx

  atoi_exit:
  	pop		es ds di si cx
  	ret

atoi_hex:
	mov		byte[di], 0	;remove 'h' at the end of line
	cmp		byte[si], 0
	je		atoi_error

	cmp		byte[si], '0'
	jb		atoi_error
	cmp		byte[si], '9'
	ja		atoi_error

	mov		cx, 10h
	xor		ax, ax
	xor		bx, bx
  atoi_hex_loop:
  	mov		bl, [si]
	inc		si

	test	bl, bl
	jz		atoi_success

	mov		di, ax
	mov		ax, dx
  	mul		cx
	xchg	ax, di
	mul		cx
	add		dx, di

	cmp		bl, '0'
	jb		atoi_hex_not_digit
	cmp		bl, '9'
	ja		atoi_hex_not_digit

	sub		bl,'0'
	jmp		atoi_hex_add

  atoi_hex_not_digit:
  	cmp		bl, 'a'
	jb		atoi_error
	cmp		bl, 'f'
	ja		atoi_error

	sub		bl, 'a' - 10

  atoi_hex_add:
  	add		ax, bx
	jmp		atoi_hex_loop
