#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>

#define MAXARGS 255
/*#define DEBUG 1*/

const char* perl = "/usr/bin/perl";
const char* path = "/usr/local/libexec/check_perc5i.pl";

int main(int argc, char* argv[]) {

  char* new_args[MAXARGS + 2];
  int i;

  if (argc >= MAXARGS) {
    printf ("arg overflow (> %d args)\n", MAXARGS);
    return 1;
  }

  setuid(0);
  seteuid(0);

  new_args[0] = (char*) perl;
  new_args[1] = (char*) path;
  for (i=1; i<argc; i++) {
    new_args[i+1] = argv[i];
  }
  new_args[argc+1] = NULL;
#ifdef DEBUG
  i = 0;
  while (new_args[i] != NULL) {
    printf ("%d = %s\n", i, new_args[i]);
    i++;
  }
#endif
  execv(perl, new_args);
  perror("Unable to exec perl!");

  return 1;
}


