%include "exception.i"

%rename(ModFormat) modformat;

#ifdef SWIGJAVA
%include "bindings/java.i"
#endif

#ifdef SWIGPYTHON
%include "bindings/python.i"
#endif

#ifdef SWIGCSHARP
%include "bindings/csharp.i"
#endif

%{
#include <stdexcept>
#include <string>
#include <iostream>

#include "haze_mod_lib.h"
%}

%nodefaultctor modlib_t;
%nodefaultctor mod_t;
%nodefaultctor modproperties_t;

%nodefaultdtor modlib_t;
%nodefaultdtor mod_t;
%nodefaultdtor modproperties_t;

struct modlib_t {};
struct mod_t {};

%ignore modlib_init;
%ignore modlib_deinit;
%ignore modlib_getErrorMessageFromCode;
%ignore modlib_queueMod;
%ignore modlib_installMods;
%ignore modlib_mod_load;
%ignore modlib_mod_deinit;
%ignore modlib_mod_getproperties;
%ignore modlib_modproperties_deinit;

%ignore modproperties_t::soft_dependencies;
%ignore modproperties_t::soft_dependency_count;
%ignore modproperties_t::dependencies;
%ignore modproperties_t::dependency_count;

%include "haze_mod_lib.h"