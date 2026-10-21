#include "include/haze_mod_lib.h"
#include "stdio.h"

int main() {
  int err = 0;

  modlib* handle = modlib_init("C:/Program Files (x86)/Steam/steamapps/common/ItTakesTwo/Nuts/", &err);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    return err;
  }

  mod* pakmod = modlib_mod_load("C:/Program Files (x86)/Steam/steamapps/common/ItTakesTwo/Mods/pak-test.hazemod", &err);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    return err;
  }

  mod* kaizomod = modlib_mod_load("C:/Program Files (x86)/Steam/steamapps/common/ItTakesTwo/Mods/kaizo.hazemod", &err);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    return err;
  }

  mod* speedtools = modlib_mod_load("C:/Program Files (x86)/Steam/steamapps/common/ItTakesTwo/Mods/Speedtools.zip", &err);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    return err;
  }

  err = modlib_queueMod(handle, pakmod);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    return err;
  }

  err = modlib_queueMod(handle, kaizomod);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    return err;
  }

  err = modlib_queueMod(handle, speedtools);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    return err;
  }

  err = modlib_installMods(handle);
  if(err != 0) {
    printf("error %s\n", modlib_getErrorMessageFromCode(err));
    return err;
  }

  printf("success\n");
  return 0;
}