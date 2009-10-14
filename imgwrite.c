/*
 * VictoriaOS: utillity program for floppy images writing
 * Copyright Ilya Strukov, 2008
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <stdio.h>
#include <stdlib.h>

#define CYL 	80
#define SECT	18
#define SSIZE 	512
#define IMAGE_SIZE (SSIZE*SECT*CYL*2)

int main(int argc, char *argv[]) {
	int offset, side, cyl, sect, sect_written;
	register int i;
	char c;
	FILE *in, *out;

	if(argc < 5) {
		printf("Usage: %s image_file side cylinder sector file\n", argv[0]);
		return 1;
	}

	side = atoi(argv[2]);
	cyl  = atoi(argv[3]);
	sect = atoi(argv[4]);

	offset = 2*SSIZE*SECT*cyl + SSIZE*SECT*side + SSIZE*(sect-1);
#ifdef DEBUG
	printf("D: offset=%d\n", offset);
#endif

	out = fopen(argv[1], "rb");
	if(out == NULL) {
		out = fopen(argv[1], "wb");
		for(i=0; i<IMAGE_SIZE; i++)
			fputc(0, out);
		fclose(out);
	} else {
		fclose(out);
	}

	out = fopen(argv[1], "r+b");
	if(out == NULL) {
		printf("Error: Can't open image file \"%s\"\n", argv[1]);
		return 2;
	}

	in = fopen(argv[5], "rb");
	if(in == NULL) {
		printf("Error: Can't open file \"%s\"\n", argv[5]);
		fclose(in);
		return 3;
	}

	fseek(out, offset, SEEK_SET);

	i = 0;
	while(1) {
		fread(&c, 1, 1, in);
		if(!feof(in))
			fwrite(&c, 1, 1, out), i++;
		else break;
	}

	sect_written = i / SSIZE + (i % SSIZE ? 1 : 0);
	printf("%d bytes, %d sectors written\n", i, sect_written);

	fclose(in);
	fclose(out);

	return 0;
}
