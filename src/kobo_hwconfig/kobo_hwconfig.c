/*
    Copyright (C) 2016 Cosmin Gorgovan <okreader at linux-geek dot org>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


    This program is part of the okreader project:
    https://github.com/lgeek/okreader
*/

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <fcntl.h>
#include <sys/mman.h>

#define HWCONFIG_OFFSET (1024 * 512)
#define HWCONFIG_MAGIC "HW CONFIG "

typedef enum {
  PRINT_ID,
  PRINT_PCB,
  PRINT_CODENAME,
  PRINT_COMMON
} print_info;

typedef enum {
  TRILOGY, KRAKEN, PIXIE, PHOENIX, PIKA, ALYSSUM, DRAGON, DAHLIA, UNKNOWN
} CODENAMES;

typedef struct  __attribute__ ((__packed__)) {
  char    magic[10];
  char    version[5];
  uint8_t size;
  uint8_t pcb_id;
} hwconfig;

char *pcbs[] = {
  "E60800", "E60810", "E60820", "E90800",  "E90810",  "E60830",  "E60850", "E50800", // 0 - 7
  "E50810", "E60860", "E60MT2", "E60M10",  "E60610",  "E60M00",  "E60M30", "E60620", // 8 - 15
  "E60630", "E60640", "E50600", "E60680",  "E60610C", "E60610D", "E606A0", "E60670", // 16 - 23
  "E606B0", "E50620", "Q70Q00", "E50610",  "E606C0",  "E606D0",  "E606E0", "E60Q00", // 24 - 31
  "E60Q10", "E60Q20", "E606F0", "E606F0B", "E60Q30",  "E60QB0",  "E60QC0", "A13120", // 32 - 39
  "E60Q50", "E606G0", "E60Q60", "E60Q80",  "A13130",  "E606H2",  "E60Q90", "ED0Q00", // 40 - 47
  "E60QA0", "E60QD0" // 48 - 49
};

uint8_t pcb_to_name[] = {
  UNKNOWN,  UNKNOWN,  UNKNOWN,  UNKNOWN,   UNKNOWN,   UNKNOWN,   UNKNOWN,  UNKNOWN,
  UNKNOWN,  UNKNOWN,  UNKNOWN,  UNKNOWN,   UNKNOWN,   UNKNOWN,   UNKNOWN,  UNKNOWN,
  UNKNOWN,  UNKNOWN,  UNKNOWN,  UNKNOWN,   UNKNOWN,   TRILOGY,   UNKNOWN,  UNKNOWN,
  KRAKEN,   UNKNOWN,  UNKNOWN,  PIXIE,     DRAGON,    UNKNOWN,   UNKNOWN,  UNKNOWN,
  UNKNOWN,  UNKNOWN,  PHOENIX,  PHOENIX,   UNKNOWN,   KRAKEN,    UNKNOWN,  UNKNOWN,
  UNKNOWN,  DAHLIA,   UNKNOWN,  UNKNOWN,   UNKNOWN,   UNKNOWN,   ALYSSUM,  UNKNOWN,
  UNKNOWN,  UNKNOWN
};

char *codenames[] = {
  "trilogy", "kraken", "pixie", "phoenix", "pika",       "alyssum", "dragon",  "dahlia",   "?"
};
char *names[] = {
  "touch",   "glo",    "mini",  "aura",    "touch 2.0?", "glo hd",  "aura hd", "aura h2o", "?"
};

char *get_pcb_name(uint8_t pcb_id) {
  if (pcb_id < (sizeof(pcbs) / sizeof(pcbs[0]))) {
    return pcbs[pcb_id];
  } else {
    return "Unknown PCB id\n";
  }
}

char *get_name(uint8_t pcb_id, print_info type) {
  int idx = -1;

  if (pcb_id < (sizeof(pcbs) / sizeof(pcbs[0]))) {
    idx = pcb_to_name[pcb_id];
    if (type == PRINT_CODENAME) {
      return codenames[idx];
    } else if (type == PRINT_COMMON) {
      return names[idx];
    }
  }

  return "Unknown name\n";
}

void print_syntax() {
  printf("Usage: kobo_hwconfig file [options]\n"
        "Options:\n"
        "  -id          Print the hwconfig PCB id\n"
        "  -pcb         Print the PCB's model no.\n"
        "  -codename    Print the device's codename\n"
        "  -common      Print the device's common marketing name\n");
}

int main(int argc, char **argv) {
  FILE *file;
  print_info output_type = PRINT_CODENAME;
  hwconfig config;
  int ret;

  if (argc < 2 || argc > 3) {
    print_syntax();
    exit(EXIT_FAILURE);
  }

  if (argc == 3) {
    if (strcmp(argv[2], "-id") == 0) {
      output_type = PRINT_ID;
    } else if (strcmp(argv[2], "-pcb") == 0) {
      output_type = PRINT_PCB;
    } else if (strcmp(argv[2], "-codename") == 0) {
      output_type = PRINT_CODENAME;
    } else if (strcmp(argv[2], "-common") == 0) {
      output_type = PRINT_COMMON;
    } else {
      fprintf(stderr, "Unknown argument: %s\n", argv[2]);
      print_syntax();
      exit(EXIT_FAILURE);
    }
  }

  file = fopen(argv[1], "rb");
  if (file == NULL) {
    fprintf(stderr, "Failed to open the input file %s\n", argv[1]);
    exit(EXIT_FAILURE);
  }

  ret = fseek(file, HWCONFIG_OFFSET, SEEK_SET);
  if (ret != 0) {
    fprintf(stderr, "Failed to seek to position 0x%x in %s\n", HWCONFIG_OFFSET, argv[1]);
    exit(EXIT_FAILURE);
  }

  ret = fread(&config, sizeof(config), 1, file);
  if (ret != 1) {
    fprintf(stderr, "Failed to read the HWCONFIG entry in %s\n", argv[1]);
    exit(EXIT_FAILURE);
  }

  if (strncmp(config.magic, HWCONFIG_MAGIC, strlen(HWCONFIG_MAGIC)) != 0) {
    fprintf(stderr, "Input file %s does not appear to contain a HWCONFIG entry\n", argv[1]);
    exit(EXIT_FAILURE);
  }

  switch (output_type) {
    case PRINT_ID:
      printf("%d\n", config.pcb_id);
      break;
    case PRINT_PCB:
      printf("%s\n", get_pcb_name(config.pcb_id));
      break;
    case PRINT_CODENAME:
      printf("%s\n", get_name(config.pcb_id, PRINT_CODENAME));
      break;
    case PRINT_COMMON:
      printf("%s\n", get_name(config.pcb_id, PRINT_COMMON));
      break;
  }

  return 0;
}

