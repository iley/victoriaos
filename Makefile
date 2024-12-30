FASM=fasm
QEMU=qemu-system-i386

BINFILES=\
	prog/type.bin \
	prog/cp.bin \
	prog/ve/ve.bin \
	prog/chmod.bin \
	prog/touch.bin \
	prog/hello.bin \
	prog/mandel.bin \
	prog/ls.bin \
	prog/clock.bin \
	prog/rm.bin \
	prog/ver.bin \
	prog/mv.bin \
	prog/jolia.bin \
	prog/clear.bin \
	kernel.bin \
	shell.bin \
	loader.bin

default: disk.img

run: disk.img
	$(QEMU) -m 1 -drive file=disk.img,index=0,if=floppy,format=raw -boot a

debug: disk.img
	$(QEMU) -m 1 -fda disk.img -boot a -s -S

disk.img: imgwrite $(BINFILES)
	./imgwrite disk.img  0  0  1 loader.bin
	./imgwrite disk.img  0  0  2 fat.bin
	./imgwrite disk.img  0  0 14 dir.bin
	./imgwrite disk.img  0  1  1 prog/rm.bin
	./imgwrite disk.img  0  1  2 prog/mv.bin
	./imgwrite disk.img  0  1  3 prog/mandel.bin
	./imgwrite disk.img  0  1  6 prog/clear.bin
	./imgwrite disk.img  0  1  7 prog/ver.bin
	./imgwrite disk.img  0  1  8 prog/jolia.bin
	./imgwrite disk.img  0  1 11 logo.bin
	./imgwrite disk.img  0  1 13 prog/touch.bin
	./imgwrite disk.img  0  1 14 prog/clock.bin
	./imgwrite disk.img  0  1 15 prog/ve/ve.bin
	./imgwrite disk.img  1  0  3 kernel.bin
	./imgwrite disk.img  1  0 13 shell.bin
	./imgwrite disk.img  1  0 14 prog/hello.bin
	./imgwrite disk.img  1  0 15 prog/ls.bin
	./imgwrite disk.img  1  0 16 prog/type.bin
	./imgwrite disk.img  1  0 17 prog/cp.bin
	./imgwrite disk.img  1  1  4 autoexec.bin
	./imgwrite disk.img  1  1  5 prog/chmod.bin

prog/ls.asm: stdlib/string/strlen.inc

kernel.asm: victoria.inc proc_table.inc const.inc errors.inc string.inc fs.inc int.inc memory.inc exec.inc arrays.inc

shell.asm: victoria.inc string.inc

loader.asm: victoria.inc const.inc

clean:
	rm -f disk.img $(BINFILES) imgwrite

string.inc: stdlib/string.inc
stdlib/string.inc: stdlib/memset.inc stdlib/string/strcpy.inc stdlib/string/strcmp.inc stdlib/string/strlen.inc stdlib/string/strtok.inc

$(BINFILES): %.bin: %.asm victoria.inc
	$(FASM) $< $@

imgwrite: imgwrite.c
	$(CC) -o imgwrite imgwrite.c

vfs: vfs.c
	$(CC) -o vfs vfs.c
