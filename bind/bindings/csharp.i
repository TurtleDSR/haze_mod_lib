//c# only interface

%module HazeModLib

%pragma(csharp) imclassclassmodifiers="internal class"

%exception {
  try {
    $action;
  } catch(const std::exception& e) {
    SWIG_exception(SWIG_RuntimeError, e.what());
    return $null;
  }
}

%rename(Mod) mod_t;
%extend mod_t {
  mod_t(const char* file) { //constructor
    int err = 0;
    struct mod_t* handle = modlib_mod_load(file, &err);

    if(err != 0) {
      throw std::runtime_error(modlib_getErrorMessageFromCode(err));
    }

    return handle;
  }

  ~mod_t() { //destructor
    if($self) {
      modlib_mod_deinit($self);
    }
  }
}

%rename(ModLib) modlib_t;
%extend modlib_t {
  modlib_t(const char* path) { //constructor
    int err = 0;
    struct modlib_t* handle = modlib_init(path, &err);

    if(err != 0) {
      throw std::runtime_error(modlib_getErrorMessageFromCode(err));
    }

    return handle;
  }

  ~modlib_t() { //destructor
    if($self) {
      modlib_deinit($self);
    }
  }

  void QueueMod(struct mod_t* mod) {
    if (!$self) {
      throw std::runtime_error("ModLib instance is null (already closed or uninitialized).");
    }
    if (!mod) {
      throw std::runtime_error("Cannot queue a null Mod instance.");
    }

    int err = modlib_queueMod($self, mod);
    if(err != 0) {
      throw std::runtime_error(modlib_getErrorMessageFromCode(err));
    }
  }

  void InstallMods() {
    if (!$self) {
      throw std::runtime_error("ModLib instance is null (already closed or uninitialized).");
    }

    int err = modlib_installMods($self);
    if(err != 0) {
      throw std::runtime_error(modlib_getErrorMessageFromCode(err));
    }
  }
}

%ignore modlib_init;
%ignore modlib_deinit;
%ignore modlib_getErrorMessageFromCode;
%ignore modlib_queueMod;
%ignore modlib_installMods;
%ignore modlib_mod_load;
%ignore modlib_mod_deinit;