; VictoriaOS: strupr function

;================================================
; #proc strupr
; #input: ds:si - string to change
; #output: none
strupr:
	push	ax si di es
	push	ds
	pop		es

	mov		di, si
  strupr_loop:
  	lodsb
	test	al, al
	jz		strupr_loop_exit
	cmp		al, 'a'
	jb		strupr_no_change
	cmp		al, 'z'
	ja		strupr_no_change
	add		al, 'A' - 'a'
  strupr_no_change:
	stosb
	jmp		strupr_loop
  strupr_loop_exit:

	pop		es di si ax
	ret
;-- vim: set filetype=fasm:
