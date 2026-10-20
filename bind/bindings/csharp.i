//c# only interface

%module ModLib

%pragma(csharp) imclassclassmodifiers="internal class"

%rename(ModLib) modlib_t;
%rename(ModLib) modlib;

%rename(Init) modlib_init;
%rename(Destroy) modlib_deinit;