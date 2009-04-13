; VictoriaOS: binpos functin implementation
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

;================================================
; #proc binpos
; search for the literal string in sorted array
; #input: ds:si - string, ds:di - start of array
; #input: dx - size of one string in the array (< 256)
; #input: cx - amount of strings in the array (< 256)
; #output: ds:si - string in array
; #output: bx - error flag
binpos:
	push	ax cx dx di es
	push	ds
	pop		es
  binpos_loop:
  	cmp		cx, 1
	jbe		binpos_loop_exit
  	mov		ax, cx
	shr		ax, 1
	mul		dl		; ax = (n/2) * sizeof(arr[0])
	mov		bx, di
	add		bx, ax	; bx = arr + (n/2) * sizeof(arr[0]) = &arr[n/2]
	xchg	bx, di
	call	strcmp	; strcmp (string, &arr[n/2])
	jae		binpos_loop_next	;if string < &arr then di should be &arr[n/2], but it is already so.
	mov		di, bx	;else di souldn't change
	shr		cx, 1	; n = n/2
	jmp		binpos_loop
  binpos_loop_next:
  	mov		ax, cx
	shr		ax, 1
	sub		cx, ax
	jmp		binpos_loop
  binpos_loop_exit:
  	xchg	si, di
	xor		bx, bx
  	call	strcmp	; strcmp (string, arr[k])
	je		binpos_exit
	xor		si, si
	inc		bx
  binpos_exit:
  	pop		es di dx cx ax
  	ret
