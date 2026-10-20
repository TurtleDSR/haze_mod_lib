//java only interface
%module HazeModLib

%include "exception.i"

%pragma(java) jniclassclassmodifiers="class"

%pragma(java) jniclasscode=%{
  static {
    try {
      System.loadLibrary("haze_mod_lib");
    } catch (UnsatisfiedLinkError e) {
      System.err.println("haze_mod_lib.dll failed to load.\n" + e);
      System.exit(1);
    }
  }
%}

%typemap(in, numinputs=0) int *err (int temp_err = 0) {
  $1 = &temp_err;
}

%typemap(argout) int *err {
  if (*$1 != 0) {
    SWIG_JavaThrowException(jenv, SWIG_JavaRuntimeException, modlib_getErrorMessageFromCode(*$1));
    return $null;
  }
}

%rename(Mod) mod_t;
%extend mod_t {
  mod_t(const char* file) { //constructor
    int err = 0;
    return modlib_mod_load(file, &err);
  }

  ~mod_t() { //destructor
    modlib_mod_deinit($self);
  }
}


%rename(ModLib) modlib_t;
%extend modlib_t {
  modlib_t(const char* path) { //constructor
    int err = 0;
    return modlib_init(path, &err);
  }

  ~modlib_t() { //destructor
    modlib_deinit($self);
  }

  void queueMod(struct mod_t* mod) {
    modlib_queueMod($self, mod);
  }

  void installMods() {
    modlib_installMods($self);
  }
}

%ignore modlib_init;
%ignore modlib_deinit;
%ignore modlib_getErrorMessageFromCode;
%ignore modlib_queueMod;
%ignore modlib_installMods;
%ignore modlib_mod_load;
%ignore modlib_mod_deinit;
