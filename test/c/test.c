#include "include/haze_mod_lib.h"
#include "stdio.h"

int main() {
  int err = 0;

  modlib* handle = NULL;
  mod* mod = NULL;

  handle = modlib_init("test/static/sandbox/", &err);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    goto CLEANUP;
  }

  mod = modlib_mod_load("test/static/mods/test.hazemod", &err);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    goto CLEANUP;
  }
  err = modlib_queueMod(handle, mod);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    goto CLEANUP;
  }

  err = modlib_installMods(handle);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    goto CLEANUP;
  }

  printf("success\n");
  return 0;

  CLEANUP:
  if(handle != NULL) modlib_deinit(handle);
  if(mod != NULL) modlib_mod_deinit(mod);
  return -1;
}