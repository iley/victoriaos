// VictoriaOS: utility for accessing VictoriaFS from other OS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
  MODE_NONE,
  MODE_LIST,
  MODE_READ,
  MODE_WRITE,
  MODE_DELETE
} t_mode;

#pragma pack(push, 1)
struct t_inode {
  char name[10];
  short int attr;
  short int len;
  short int clust;
};
#pragma pack(pop)

#define DEFAULT_ATTR 5

#define MAX_FILES 128 // maximal amount of file name parameters
#define CLUST_SIZE 512

#define FAT_START 2
#define FAT_LEN 12
#define DIR_START 14
#define DIR_LEN 2
#define DATA_START (DIR_START + DIR_LEN + 1)

#define FAT_FREE 0
#define FAT_EOF (-1)

#define FAT_SIZE (FAT_LEN * CLUST_SIZE / sizeof(short int))
#define INODE_COUNT (CLUST_SIZE * DIR_LEN / sizeof(struct t_inode))

#define set_mode(new_mode)                                                     \
  {                                                                            \
    if (mode != MODE_NONE) {                                                   \
      printf("Error: You must specify only ONE mode option\n");                \
      return 1;                                                                \
    }                                                                          \
    mode = (new_mode);                                                         \
  }
#define is_clust(num) ((num) != 0 && (num) != 0xffff)

inline int clust2filepos(int clust) { // return file offset for cluster # clust
  return (clust - 1) * CLUST_SIZE;
}

void load_dir(struct t_inode *dir, FILE *file) {
  fseek(file, clust2filepos(DIR_START), SEEK_SET);
  fread(dir, sizeof(struct t_inode), INODE_COUNT, file);
}

void load_fat(short int fat[], FILE *file) {
  fseek(file, clust2filepos(FAT_START), SEEK_SET);
  fread(fat, sizeof(short int), FAT_SIZE, file);
}

void save_dir(struct t_inode *dir, FILE *file) {
  fseek(file, clust2filepos(DIR_START), SEEK_SET);
  fwrite(dir, sizeof(struct t_inode), INODE_COUNT, file);
}

void save_fat(short int *fat, FILE *file) {
  fseek(file, clust2filepos(FAT_START), SEEK_SET);
  fwrite(fat, sizeof(struct t_inode), INODE_COUNT, file);
}

int find_inode(char *file_name, struct t_inode dir[]) {
  register int i;

  for (i = 0; i < INODE_COUNT; i++)
    if (strcmp(file_name, dir[i].name) == 0)
      return i;

  return -1;
}

int alloc_clust(short int fat[]) {
  register int i;
  for (i = DATA_START; i < FAT_SIZE; i++)
    if (fat[i] == FAT_FREE)
      return i;
  return -1;
}

int alloc_inode(struct t_inode dir[]) {
  register int i;
  for (i = 0; i < INODE_COUNT; i++)
    if (dir[i].name[0] == '\0')
      return i;
  return -1;
}

void remove_chain(int first_clust, short int fat[]) {
  register int i;
  int oi;
  i = first_clust;
  while (i != FAT_EOF) {

    // printf("D: Removing cluster 0x%x\n", i);

    if (i == FAT_FREE) {
      printf("Error: Invalid cluster number while removing old file\n");
      exit(1);
    }

    oi = i;
    i = fat[i];
    fat[oi] = FAT_FREE;
  }
}

int main(int argc, char *argv[]) {
  const char *help_message = "\
VictoriaFS management program. Copyright Ilya Strukov, 2008\n\
Usage: vfs option image_file [file1 file2 ...]\n\
Options: -h show this help\n\
         -l list files on image\n\
         -r read file from image\n\
         -w write file to image\n\
         -d delete file from image\n";

  register int i;
  int filenum = 0, fi, c, oc, ch;
  char *img_filename = NULL, *filename = NULL;
  FILE *file, *img_file;
  t_mode mode = MODE_NONE;
  struct t_inode dir[INODE_COUNT];
  short int fat[FAT_SIZE];

  for (i = 1; i < argc; i++) {
    if (argv[i][0] == '-') // this arg is an option
      switch (argv[i][1]) {
      case 'h':
        printf(help_message);
        return 0;
        break;
      case 'l':
        set_mode(MODE_LIST);
        break;
      case 'r':
        set_mode(MODE_READ);
        break;
      case 'w':
        set_mode(MODE_WRITE);
        break;
      case 'd':
        set_mode(MODE_DELETE);
        break;
      default:
        printf("Error: Unknow command line option: \"%s\"\n", argv[i]);
        return 1;
      }
    else if (!img_filename)
      img_filename = argv[i];
    else if (!filename)
      filename = argv[i];
    else {
      printf("Error: Too many file names\n");
      return 1;
    }
  }

  if (!img_filename || (!filename && (mode == MODE_READ || mode == MODE_WRITE ||
                                      mode == MODE_DELETE))) {
    printf(help_message);
    return 1;
  }

  switch (mode) {
  case MODE_NONE:
    printf("Error: You must specify action\n\n");
    printf(help_message);
    return 1;
  case MODE_LIST: // just print list of files
    if (!(img_file = fopen(img_filename, "rb"))) {
      printf("Error: Couln't open file \"%s\"\n", img_filename);
      return 1;
    }
    fseek(img_file, clust2filepos(DIR_START), SEEK_SET);
    fread(dir, sizeof(struct t_inode), INODE_COUNT, img_file);

    load_dir(dir, img_file);

    for (i = 0; i < INODE_COUNT; i++)
      if (dir[i].name[0])
        printf("%s\n", dir[i].name);

    fcloseall();
    break;
  case MODE_READ:
    if (!(img_file = fopen(img_filename, "rb"))) {
      printf("Error: Couldn't open file \"%s\"\n", img_filename);
      return 1;
    }

    load_dir(dir, img_file);
    load_fat(fat, img_file);

    fi = find_inode(filename, dir);
    if (fi == -1) {
      printf("Error: There is no such file \"%s\" on image \"%s\"\n", filename,
             img_filename);
      fcloseall();
      return 1;
    }

    if (!(file = fopen(filename, "wb"))) {
      printf("Error: Couldn't open file \"%s\"\n", filename);
      return 1;
    }

    c = dir[fi].clust;
    for (i = 0; i < dir[fi].len; i++) {
      if (i % CLUST_SIZE == 0) {
        if (!is_clust(c)) {
          printf("Error: Incorrect cluster number (reading cluster %d)\n",
                 i / CLUST_SIZE);
          return 1;
        }

        // printf("D: cluster 0x%x, filepos 0x%x\n", c, clust2filepos(c));

        fseek(img_file, clust2filepos(c), SEEK_SET);
        c = fat[c];
      }

      fputc(fgetc(img_file), file);
    }

    fcloseall();
    break;

  case MODE_WRITE:
    if (!(img_file = fopen(img_filename, "r+b"))) {
      printf("Error: Couldn't open file \"%s\"\n", img_filename);
      return 1;
    }

    load_dir(dir, img_file);
    load_fat(fat, img_file);

    if (strlen(filename) > sizeof(dir[0].name) - 1) {
      printf("Error: File name is too long\n");
      fcloseall();
      return 1;
    }

    if (!(file = fopen(filename, "rb"))) {
      printf("Error: Couldn't open file \"%s\"\n", filename);
      fcloseall();
      return 1;
    }

    fi = find_inode(filename, dir);
    if (fi == -1) {
      fi = alloc_inode(dir);
      if (fi == -1) {
        printf("Error: Too many files on this image\n");
        fcloseall();
        return 1;
      }
    } else                              // if file exists
      remove_chain(dir[fi].clust, fat); // remove old file

    i = 0;
    while ("Microsoft sucks") {
      ch = fgetc(file);
      if (ch == EOF)
        break;

      if (i % CLUST_SIZE == 0) { // allocate new cluster
        oc = c;
        c = alloc_clust(fat);
        if (i == 0)
          dir[fi].clust = c;
        else
          fat[oc] = c;
        fat[c] = FAT_EOF;

        // printf("D: allocating cluster 0x%x, i=0x%x\n", c, i);

        fseek(img_file, clust2filepos(c), SEEK_SET);
      }

      fputc(ch, img_file);
      i++;
    }

    strcpy(dir[fi].name, filename);
    dir[fi].attr = DEFAULT_ATTR;
    dir[fi].len = i;

    save_dir(dir, img_file);
    save_fat(fat, img_file);

    fcloseall();
    break;

  case MODE_DELETE:
    if (!(img_file = fopen(img_filename, "r+b"))) {
      printf("Error: Couldn't open file \"%s\"\n", img_filename);
      return 1;
    }

    load_dir(dir, img_file);
    load_fat(fat, img_file);

    fi = find_inode(filename, dir);
    if (fi == -1) {
      printf("Error: File does not exists\n");
      fcloseall();
      return 1;
    }

    remove_chain(dir[fi].clust, fat); // clear fat
    dir[fi].name[0] = 0;              // clear directory

    save_dir(dir, img_file);
    save_fat(fat, img_file);

    fcloseall();
    break;

  default:
    printf("Error: Invalid mode\n");
    return 1;
  }

  return 0;
}
