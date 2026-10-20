#include "include/haze_mod_lib.h"
#include "stdio.h"

int main() {
  int err = 0;

  modlib* handle = modlib_init("test/static/sandbox/", &err);
  if(err != 0) {
    printf("error %i\n", err);
    return err;
  }

  mod* mod = modlib_mod_load("test/static/mods/test.hazemod", &err);
  if(err != 0) {
    printf("error %i\n", err);
    return err;
  }

  err = modlib_queueMod(handle, mod);
  if(err != 0) {
    printf("error %i\n", err);
    return err;
  }

  err = modlib_installMods(handle);
  if(err != 0) {
    printf("error %i\n", err);
    return err;
  }

  printf("success\n");
  return 0;
}