FASM=fasm
IMAGE_FILE=disk.img
IMGWRITE=./imgwrite

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

EXTRA_BINFILES= \
	fat.bin \
	autoexec.bin \
	logo.bin \
	dir.bin

default: $(IMAGE_FILE)

run: $(IMAGE_FILE)
	qemu -m 1 -fda $(IMAGE_FILE) -boot a

debug: $(IMAGE_FILE)
	qemu -m 1 -fda $(IMAGE_FILE) -boot a -s -S

$(IMAGE_FILE): $(IMGWRITE) $(BINFILES)
	$(IMGWRITE) $(IMAGE_FILE) 0 1 11 logo.bin
	$(IMGWRITE) $(IMAGE_FILE) 1 1  4 autoexec.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 0 14 dir.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 0  2 fat.bin
	$(IMGWRITE) $(IMAGE_FILE) 1 0 16 prog/type.bin
	$(IMGWRITE) $(IMAGE_FILE) 1 0 17 prog/cp.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 1 15 prog/ve/ve.bin
	$(IMGWRITE) $(IMAGE_FILE) 1 1  5 prog/chmod.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 1 13 prog/touch.bin
	$(IMGWRITE) $(IMAGE_FILE) 1 0 14 prog/hello.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 1 3 prog/mandel.bin
	$(IMGWRITE) $(IMAGE_FILE) 1 0 15 prog/ls.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 1 14 prog/clock.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 1 1 prog/rm.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 1 7 prog/ver.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 1 2 prog/mv.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 1 8 prog/jolia.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 1 6 prog/clear.bin
	$(IMGWRITE) $(IMAGE_FILE) 1 0 3 kernel.bin
	$(IMGWRITE) $(IMAGE_FILE) 1 0 13 shell.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 0 1 loader.bin

prog/ls.asm: stdlib/string/strlen.inc

kernel.asm: victoria.inc proc_table.inc const.inc errors.inc string.inc fs.inc int.inc memory.inc exec.inc arrays.inc

shell.asm: victoria.inc string.inc

loader.asm: victoria.inc const.inc

clean:
	rm -f $(IMAGE_FILE) $(BINFILES) $(IMGWRITE)

string.inc: stdlib/string.inc
stdlib/string.inc: stdlib/memset.inc stdlib/string/strcpy.inc stdlib/string/strcmp.inc stdlib/string/strlen.inc stdlib/string/strtok.inc

$(BINFILES): %.bin: %.asm victoria.inc
	fasm $< $@

imgwrite: imgwrite.c
	$(CC) -o imgwrite imgwrite.c

vfs: vfs.c
	$(CC) -o vfs vfs.c
