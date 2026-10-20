//python only interface

%module mod_lib

%rename("_ModLibJNI") ModLibJNI;

%rename(modlib) modlib_t;
%rename(modlib) modlib;

%rename(init) modlib_init;
%rename(destroy) modlib_deinit;