//c# only interface

%module HazeModLib

%include <std_vector.i>
%include <std_string.i>

namespace std {
  %template(StringList) vector<string>;
}

%exception {
  try {
    $action;
  } catch(const std::exception& e) {
    SWIG_exception(SWIG_RuntimeError, e.what());
    return $null;
  }
}

%rename(ModProperties) modproperties_t;
%extend modproperties_t {
  ~modproperties_t() { //destructor
    if($self) {
      modlib_modproperties_deinit($self);
    }
  }

  std::vector<std::string> GetDependencies() {
    std::vector<std::string> vec;
    if ($self->dependencies && $self->dependency_count > 0) {
      vec.reserve($self->dependency_count);
      for (unsigned long long i = 0; i < $self->dependency_count; ++i) {
        if ($self->dependencies[i]) {
          vec.push_back($self->dependencies[i]);
        }
      }
    }
    return vec;
  }

  std::vector<std::string> GetSoftDependencies() {
    std::vector<std::string> vec;
    if ($self->soft_dependencies && $self->soft_dependency_count > 0) {
      vec.reserve($self->soft_dependency_count);
      for (unsigned long long i = 0; i < $self->soft_dependency_count; ++i) {
        if ($self->soft_dependencies[i]) {
          vec.push_back($self->soft_dependencies[i]);
        }
      }
    }
    return vec;
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

  modproperties_t* GetProperties() {
    int err = 0;
    struct modproperties_t* handle = modlib_mod_getproperties($self, &err);

    if(err != 0) {
      throw std::runtime_error(modlib_getErrorMessageFromCode(err));
    }

    return handle;
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