; VictoriaOS: memset (C stdlib analog) function
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

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
