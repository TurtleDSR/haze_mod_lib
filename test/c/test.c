#include "include/haze_mod_lib.h"
#include "stdio.h"

int main() {
  int err = 0;

  modlib* handle = NULL;
  mod* pakmod = NULL;
  mod* kaizomod = NULL;
  mod* speedtools = NULL;

  handle = modlib_init("C:/Program Files (x86)/Steam/steamapps/common/ItTakesTwo/Nuts/", &err);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    goto CLEANUP;
  }

  pakmod = modlib_mod_load("C:/Program Files (x86)/Steam/steamapps/common/ItTakesTwo/Mods/pak-test.hazemod", &err);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    goto CLEANUP;
  }

  kaizomod = modlib_mod_load("C:/Program Files (x86)/Steam/steamapps/common/ItTakesTwo/Mods/kaizo.hazemod", &err);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    goto CLEANUP;
  }

  speedtools = modlib_mod_load("C:/Program Files (x86)/Steam/steamapps/common/ItTakesTwo/Mods/Speedtools.zip", &err);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    goto CLEANUP;
  }

  err = modlib_queueMod(handle, pakmod);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    goto CLEANUP;
  }

  err = modlib_queueMod(handle, kaizomod);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    goto CLEANUP;
  }

  err = modlib_queueMod(handle, speedtools);
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
  if(pakmod != NULL) modlib_mod_deinit(pakmod);
  if(kaizomod != NULL) modlib_mod_deinit(kaizomod);
  if(speedtools != NULL) modlib_mod_deinit(speedtools);
  return -1;
}