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

$(IMAGE_FILE): $(BINFILES)
	$(IMGWRITE) $(IMAGE_FILE) 0 1 11 logo.bin
	$(IMGWRITE) $(IMAGE_FILE) 1 1 4 autoexec.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 0 14 dir.bin
	$(IMGWRITE) $(IMAGE_FILE) 0 0 2 fat.bin

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
