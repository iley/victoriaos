; VictoriaOS: memset (C stdlib analog) function

;================================================
; #proc memset
; #input: ds:di - string to fill, al - character, cx - length
; #output: none
memset:
	push	ax cx di es
	push	ds
	pop		es
	cld
	rep		stosb
	pop		es di cx ax
	ret
;-- vim: set filetype=fasm:
