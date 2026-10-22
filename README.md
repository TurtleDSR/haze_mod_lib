# Library for installing mods to Angelscript Unreal games
### Most work in this library is done to preprocess the Fog preprocessor language.
### It can be used to patch functions and classes without the overhead of runtime patching and sideloading.

* Installs mods with a sophisticated multi-threaded implementation that respects dependencies.
* Handles both .zip format and .hazemod format.
* Written in Zig.
* Bindings for C, Java, C# and Python.

## Credits:
* TurtleDSR (All non-external code was written by me)
* Kuba (External Zip Library) (zig bindings were written by me)
* Huge credit to the authors of SWIG, it makes generating the bindings from C to Java, Python and C# possible without a huge headache.

## [Fog Language Reference](DOCS.md)