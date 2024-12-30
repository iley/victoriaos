; VictoriaOS: strlwr function

;================================================
; #proc strlwr
; #input: ds:si - string to change
; #output: none
strlwr:
	push	ax si di es
	push	ds
	pop		es

	mov		di, si
  strlwr_loop:
  	lodsb
	test	al, al
	jz		strlwr_loop_exit
	cmp		al, 'A'
	jb		strlwr_no_change
	cmp		al, 'Z'
	ja		strlwr_no_change
	add		al, 'a' - 'A'
  strlwr_no_change:
	stosb
	jmp		strlwr_loop
  strlwr_loop_exit:

	pop		es di si ax
	ret
;-- vim: set filetype=fasm:
