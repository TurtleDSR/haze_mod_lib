build:
  @clear
  @zig build

bind: build
  @clear
  @zig build bind

  @rm -rf .out/wrap/

  @[ -d .out/wrap/java/com/turtledsr/hazemodlib ] || mkdir -p .out/wrap/java/com/turtledsr/hazemodlib
  @[ -d .out/wrap/python/ ] || mkdir -p .out/wrap/python/
  @[ -d .out/wrap/csharp/ ] || mkdir -p .out/wrap/csharp/

  @cp zig-out/lib/haze_mod_lib_static.lib bind/include/haze_mod_lib.lib
  @cp zig-pkg/zip-1.0.4-17qA5UcTHwB6CVYazmkLoacjgUas9NAwGmxVtmy7wEBx/lib/zip_c.lib bind/include/zip_c.lib

  swig -java -c++ -package com.turtledsr.hazemodlib -outdir .out/wrap/java/com/turtledsr/hazemodlib -o .out/wrap/java/haze_mod_lib_wrap.cxx bind/haze_mod_lib.i
  @rm .out/wrap/java/com/turtledsr/hazemodlib/HazeModLib.java

  swig -csharp -c++ -namespace Com.Turtledsr.HazeModLib -outdir .out/wrap/csharp -o .out/wrap/csharp/haze_mod_lib_wrap.cxx bind/haze_mod_lib.i
  @rm .out/wrap/csharp/HazeModLib.cs

  swig -python -c++ -outdir .out/wrap/python -o .out/wrap/python/haze_mod_lib_wrap.cxx bind/haze_mod_lib.i

lint: build
  @clear
  @zig build lint

test: build
  @clear
  @[ -d test/static/sandbox/Script ] || mkdir -p test/static/sandbox/Script
  @#@unzip -o test/static/sandbox/scripts.zip -d test/static/sandbox/Script/
  @zig build test --summary all

build-c: bind #c build script
  @cp zig-out/bin/haze_mod_lib.dll .out/c/test/

release: build-c
  #C
  @[ -d .out/lib/c/ ] || mkdir -p .out/lib/c/
  @cp bind/haze_mod_lib.h .out/lib/c/
  @cp zig-out/lib/haze_mod_lib.lib .out/lib/c/
  @cp zig-out/bin/haze_mod_lib.dll .out/lib/c/

  #build all swig dll's
  zig build release

  #JAVA
  @[ -d .out/lib/java/ ] || mkdir -p .out/lib/java/
  @cp zig-out/bin/haze_mod_lib_java.dll .out/lib/java/haze_mod_lib.dll
  javac --release 11 -d .out/tmp/java/jar .out/wrap/java/com/turtledsr/hazemodlib/*.java
  jar -cvf .out/lib/java/hazemodlib.jar -C .out/tmp/java/jar .

  #CSHARP
  @[ -d .out/lib/csharp/ ] || mkdir -p .out/lib/csharp/
  @[ -d .out/tmp/csharp/ ] || mkdir -p .out/tmp/csharp/
  @dotnet new classlib -o .out/tmp/csharp/haze_mod_lib --name haze_mod_lib --force
  @cp -r .out/wrap/csharp/*.cs .out/tmp/csharp/haze_mod_lib/
  @cp zig-out/bin/haze_mod_lib_csharp.dll .out/lib/csharp/haze_mod_lib.dll
  @rm .out/tmp/csharp/haze_mod_lib/Class1.cs
  @dotnet build .out/tmp/csharp/haze_mod_lib/haze_mod_lib.csproj -c Release
  @cp .out/tmp/csharp/haze_mod_lib/bin/Release/net10.0/haze_mod_lib.dll .out/lib/csharp/haze_mod_lib_csharp.dll

  #PYTHON
  @[ -d .out/lib/python/ ] || mkdir -p .out/lib/python/
  cp .out/wrap/python/haze_mod_lib.py .out/lib/python/
  @cp zig-out/bin/haze_mod_lib_python.dll .out/lib/python/_haze_mod_lib.pyd

test-c: release
  @[ -d .out/c/test/ ] || mkdir -p .out/c/test/
  @cp .out/lib/c/haze_mod_lib.h test/c/include/
  @cp .out/lib/c/haze_mod_lib.lib test/c/include/
  clang -std=c23 -O0 test/c/test.c -o .out/c/test/test.exe -Itest/c/include/ -Ltest/c/include/ -lhaze_mod_lib
  .out/c/test/test.exe

test-py: release
  @cp .out/lib/python/haze_mod_lib.py test/py/lib/
  @cp .out/lib/python/_haze_mod_lib.pyd test/py/lib/
  py test/py/test.py