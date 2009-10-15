; VictoriaOS: strtok function
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

;================================================
; #proc string tokenizer ;-)
; #input: ds:si - string or NULL, es:di - string with delims
; if ds:si == NULL, continue with previous string
; #output: ds:si - first word's address, bx != 0 in case of error and bx == 0 overwise
strtok_pword dw 0	;place to keep previous word for next strtok(NULL) calls
strtok_delims db 256 dup(0) ;strtok_delims[i] == (if this character is a delim?)
strtok:
	push	ax cx di
	cld

	test	si, si
	jnz		strtok_got_word
	mov		si, [strtok_pword]
	test	si, si
	jnz		strtok_got_word
	xor		bx, bx
	inc		bx
	jmp		strtok_exit							;return 1
  strtok_got_word:

	;clear strtok_delims
	push	di
	mov		di, strtok_delims
	mov		al, 0
	mov		cx, 256
	call	memset
	pop		di

	xchg	si, di							;si = delims
	
 	;fill strtok_delims
	xor		ax, ax
  strtok_fill_table_loop:
 	lodsb									;ax = delims[i]
	test	al, al
	jz		strtok_fill_table_loop_exit
	mov		bx, ax							;bx = delims[i]
	mov		byte [strtok_delims+bx], 0ffh	;strtok_delims[delims[i]] = TRUE
	jmp		strtok_fill_table_loop
  strtok_fill_table_loop_exit:

	mov		si, di							;si = string
	xor		ax, ax				;prepare ax for string[i]
  strtok_find_word_loop:
  	lodsb
	test	al, al
	jnz		strtok_find_word_loop_not_end_of_word	;-)
	xor		bx, bx
	mov		[strtok_pword], bx				;the string is ended :-( no more strtok(NULL) calls
	inc		bx
	jmp		strtok_exit	;return 1
  strtok_find_word_loop_not_end_of_word:
	mov		bx, ax
	cmp		byte [strtok_delims+bx], 0
	jne		strtok_find_word_loop
  
  	;so, we has found the beginning of next word, lets find the end!	  	
	;di keeps the beginning of the word, si will be used for the end
	mov		di, si
	dec		di
	xor		ax, ax
  strtok_find_end_of_the_word_i_like_such_long_names_because_they_are_funny:
  	lodsb
	test	al, al
	jnz		strtok_find_end_loop_not_end_of_word
	;oh, shit! there was no delim at the end of string
	xor		bx, bx
	mov		[strtok_pword], bx	;the string has been ended
	mov		si, di		;return start of the word in si
	jmp		strtok_exit	;return 0
  strtok_find_end_loop_not_end_of_word:
	mov		bx, ax
	cmp		byte [strtok_delims+bx], 0
	je		strtok_find_end_of_the_word_i_like_such_long_names_because_they_are_funny
	;wow! we has found end of the word!
	mov		byte [si-1], 0
	mov		[strtok_pword], si	;keep current position for next strtok(NULL) calls
	mov		si, di
	xor		bx, bx
  strtok_exit:
	pop		di cx ax
  	ret
;-- vim: set filetype=fasm:
