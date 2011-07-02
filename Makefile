FASM = ./fasm/fasm
IMAGE_FILE = disk.img
IMGWRITE = ./imgwrite

BINFILES = \
	prog/type.1.0.16.bin \
	prog/cp.1.0.17.bin \
	prog/ve/ve.0.1.15.bin \
	prog/chmod.1.1.5.bin \
	prog/touch.0.1.13.bin \
	prog/hello.1.0.14.bin \
	prog/mandel.0.1.3.bin \
	prog/ls.1.0.15.bin \
	prog/clock.0.1.14.bin \
	prog/rm.0.1.1.bin \
	prog/ver.0.1.7.bin \
	prog/mv.0.1.2.bin \
	prog/jolia.0.1.8.bin \
	prog/clear.0.1.6.bin \
	logo.0.1.11.bin \
	autoexec.1.1.4.bin \
	kernel.1.0.3.bin \
	shell.1.0.13.bin \
	dir.0.0.14.bin \
	loader.0.0.1.bin \
	fat.0.0.2.bin

default: ${IMGWRITE} ${IMAGE_FILE}

${IMGWRITE} : imgwrite.c
	gcc -o ${IMGWRITE} $^

run: ${IMAGE_FILE}
	qemu -m 1 -fda ${IMAGE_FILE} -boot a

debug: ${IMAGE_FILE}
	qemu -m 1 -fda ${IMAGE_FILE} -boot a -s -S

${IMAGE_FILE}: ${BINFILES}
	${IMGWRITE} ${IMAGE_FILE} 0 1 11 logo.0.1.11.bin
	${IMGWRITE} ${IMAGE_FILE} 1 1 4 autoexec.1.1.4.bin
	${IMGWRITE} ${IMAGE_FILE} 0 0 14 dir.0.0.14.bin
	${IMGWRITE} ${IMAGE_FILE} 0 0 2 fat.0.0.2.bin

clean:
	rm -f	disk.img
	rm -f	prog/type.1.0.16.bin && true
	rm -f	prog/cp.1.0.17.bin && true
	rm -f	prog/ve/ve.0.1.15.bin && true
	rm -f	prog/chmod.1.1.5.bin && true
	rm -f	prog/touch.0.1.13.bin && true
	rm -f	prog/hello.1.0.14.bin && true
	rm -f	prog/mandel.0.1.3.bin && true
	rm -f	prog/ls.1.0.15.bin && true
	rm -f	prog/clock.0.1.14.bin && true
	rm -f	prog/rm.0.1.1.bin && true
	rm -f	prog/ver.0.1.7.bin && true
	rm -f	prog/mv.0.1.2.bin && true
	rm -f	prog/jolia.0.1.8.bin && true
	rm -f	prog/clear.0.1.6.bin && true
	rm -f	kernel.1.0.3.bin && true
	rm -f	shell.1.0.13.bin && true
	rm -f	loader.0.0.1.bin && true

string.inc: stdlib/string.inc
stdlib/string.inc: stdlib/memset.inc stdlib/string/strcpy.inc stdlib/string/strcmp.inc stdlib/string/strlen.inc stdlib/string/strtok.inc

prog/type.1.0.16.bin: prog/type.asm victoria.inc
	${FASM} prog/type.asm prog/type.1.0.16.bin
	${IMGWRITE} ${IMAGE_FILE} 1 0 16 prog/type.1.0.16.bin
prog/cp.1.0.17.bin:  prog/cp.asm victoria.inc
	${FASM} prog/cp.asm prog/cp.1.0.17.bin 
	${IMGWRITE} ${IMAGE_FILE} 1 0 17 prog/cp.1.0.17.bin
prog/ve/ve.0.1.15.bin: prog/ve/ve.asm victoria.inc
	${FASM} prog/ve/ve.asm prog/ve/ve.0.1.15.bin 
	${IMGWRITE} ${IMAGE_FILE} 0 1 15 prog/ve/ve.0.1.15.bin
prog/chmod.1.1.5.bin: prog/chmod.asm victoria.inc
	${FASM} prog/chmod.asm prog/chmod.1.1.5.bin 
	${IMGWRITE} ${IMAGE_FILE} 1 1 5 prog/chmod.1.1.5.bin
prog/touch.0.1.13.bin: prog/touch.asm  victoria.inc
	${FASM} prog/touch.asm  prog/touch.0.1.13.bin 
	${IMGWRITE} ${IMAGE_FILE} 0 1 13 prog/touch.0.1.13.bin
prog/hello.1.0.14.bin: prog/hello.asm victoria.inc
	${FASM} prog/hello.asm prog/hello.1.0.14.bin 
	${IMGWRITE} ${IMAGE_FILE} 1 0 14 prog/hello.1.0.14.bin
prog/mandel.0.1.3.bin: prog/mandel.asm victoria.inc 
	${FASM} prog/mandel.asm prog/mandel.0.1.3.bin 
	${IMGWRITE} ${IMAGE_FILE} 0 1 3 prog/mandel.0.1.3.bin
prog/ls.1.0.15.bin: prog/ls.asm victoria.inc stdlib/string/strlen.inc
	${FASM} prog/ls.asm prog/ls.1.0.15.bin 
	${IMGWRITE} ${IMAGE_FILE} 1 0 15 prog/ls.1.0.15.bin
prog/clock.0.1.14.bin: prog/clock.asm victoria.inc
	${FASM} prog/clock.asm prog/clock.0.1.14.bin 
	${IMGWRITE} ${IMAGE_FILE} 0 1 14 prog/clock.0.1.14.bin
prog/rm.0.1.1.bin: prog/rm.asm victoria.inc
	${FASM} prog/rm.asm prog/rm.0.1.1.bin 
	${IMGWRITE} ${IMAGE_FILE} 0 1 1 prog/rm.0.1.1.bin
prog/ver.0.1.7.bin: prog/ver.asm victoria.inc
	${FASM} prog/ver.asm prog/ver.0.1.7.bin 
	${IMGWRITE} ${IMAGE_FILE} 0 1 7 prog/ver.0.1.7.bin
prog/mv.0.1.2.bin: prog/mv.asm victoria.inc
	${FASM} prog/mv.asm prog/mv.0.1.2.bin 
	${IMGWRITE} ${IMAGE_FILE} 0 1 2 prog/mv.0.1.2.bin
prog/jolia.0.1.8.bin: prog/jolia.asm victoria.inc
	${FASM} prog/jolia.asm prog/jolia.0.1.8.bin 
	${IMGWRITE} ${IMAGE_FILE} 0 1 8 prog/jolia.0.1.8.bin
prog/clear.0.1.6.bin: prog/clear.asm victoria.inc
	${FASM} prog/clear.asm prog/clear.0.1.6.bin 
	${IMGWRITE} ${IMAGE_FILE} 0 1 6 prog/clear.0.1.6.bin
kernel.1.0.3.bin: kernel.asm victoria.inc proc_table.inc const.inc errors.inc string.inc fs.inc int.inc memory.inc exec.inc arrays.inc
	${FASM} kernel.asm kernel.1.0.3.bin 
	${IMGWRITE} ${IMAGE_FILE} 1 0 3 kernel.1.0.3.bin
shell.1.0.13.bin: shell.asm victoria.inc string.inc
	${FASM} shell.asm shell.1.0.13.bin 
	${IMGWRITE} ${IMAGE_FILE} 1 0 13 shell.1.0.13.bin
loader.0.0.1.bin: loader.asm victoria.inc const.inc
	${FASM} loader.asm loader.0.0.1.bin
	${IMGWRITE} ${IMAGE_FILE} 0 0 1 loader.0.0.1.bin

imgwrite: imgwrite.c
	gcc -o imgwrite imgwrite.c

vfs: vfs.c
	gcc -o vfs vfs.c
