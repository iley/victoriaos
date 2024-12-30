; VictoriaOS: large data arrays module (must be included at the end of kernel.asm)

align 16
;=================================================
; arrays for fs.inc
fat             = $
sizeof.fat      = FAT_LEN * BYTES_PER_CLUST
io_buf          = fat + sizeof.fat
sizeof.io_buf   = BYTES_PER_CLUST
;-- vim: set filetype=fasm:
