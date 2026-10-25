#include "include/haze_mod_lib.h"
#include "stdio.h"
#include "string.h"

int main() {
  int err = 0;

  modlib* handle = NULL;
  mod* mod = NULL;
  modproperties* properties = NULL;

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

  properties = modlib_mod_getproperties(mod, &err);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    goto CLEANUP;
  }

  if(strcmp(properties->author, "TurtleDSR") != 0) {
    printf("error %s\n", "Invalid Properties");
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
  if(properties != NULL) modlib_modproperties_deinit(properties);
  return -1;
}