# Library for installing mods to Angelscript Unreal games
### Most work in this library is done to handle the Fog preprocessor language.
### It can be used to patch functions and classes without the overhead of runtime patching and sideloading.

* Installs mods with a sophisticated multi-threaded implementation that respects dependencies.
* Handles both .zip format and .hazemod format.
* Written in Zig.
* Bindings for C, Java, C#, Go, and Python.

## Usage:
  * Zig:
```bash 
zig fetch --save git+https://github.com/TurtleDSR/haze_mod_lib/
```
  * Go:
```go
import "github.com/turtledsr/haze_mod_lib/go"
```
also include the haze_mod_lib_go.dll found in [releases](https://github.com/TurtleDSR/haze_mod_lib/releases) in your binary folder
  * C, Java, C#, Python: 
Necessary files can be found in [releases](https://github.com/TurtleDSR/haze_mod_lib/releases)

## Credits:
* TurtleDSR (All non-external code was written by me)
* Kuba (External Zip Library) (zig bindings were written by me)
* Huge credit to the authors of SWIG, it makes generating the bindings from C to Java, C#, and Python possible without a huge headache. (zig to c and c to go were written by hand)

## [Fog Language Reference](DOCS.md)