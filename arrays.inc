; VictoriaOS: large data arrays module (must be included at the end of kernel.asm)
; Copyright Ilya Strukov, 2008

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

align 16
;=================================================
; arrays for fs.inc
fat             = $
sizeof.fat      = FAT_LEN * BYTES_PER_CLUST
io_buf          = fat + sizeof.fat
sizeof.io_buf   = BYTES_PER_CLUST
;-- vim: set filetype=fasm:
