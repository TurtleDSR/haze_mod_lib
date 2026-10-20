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
#include "haze_mod_lib.h"
%}

%nodefaultctor modlib_t;
%nodefaultctor mod_t;

struct modlib_t {};
struct mod_t {};

%include "haze_mod_lib.h"