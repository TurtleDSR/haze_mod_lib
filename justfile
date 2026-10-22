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

  @swig -java -c++ -package com.turtledsr.hazemodlib -outdir .out/wrap/java/com/turtledsr/hazemodlib -o .out/wrap/java/haze_mod_lib_wrap.cxx bind/haze_mod_lib.i
  @rm .out/wrap/java/com/turtledsr/hazemodlib/HazeModLib.java

  @swig -csharp -c++ -namespace Com.Turtledsr.HazeModLib -outdir .out/wrap/csharp -o .out/wrap/csharp/haze_mod_lib_wrap.cxx bind/haze_mod_lib.i
  @rm .out/wrap/csharp/HazeModLib.cs

  @swig -python -c++ -outdir .out/wrap/python -o .out/wrap/python/haze_mod_lib_wrap.cxx bind/haze_mod_lib.i

lint: build
  @clear
  @zig build lint

test: build
  @clear
  @[ -d test/static/sandbox/Script ] || mkdir -p test/static/sandbox/Script
  @zig build test --summary all

release: bind
  @#C
  @[ -d .out/lib/c/ ] || mkdir -p .out/lib/c/
  @cp bind/haze_mod_lib.h .out/lib/c/
  @cp zig-out/lib/haze_mod_lib.lib .out/lib/c/
  @cp zig-out/bin/haze_mod_lib.dll .out/lib/c/

  @#build all swig dll's
  @zig build release

  @#JAVA
  @[ -d .out/lib/java/ ] || mkdir -p .out/lib/java/
  @cp zig-out/bin/haze_mod_lib_java.dll .out/lib/java/haze_mod_lib.dll
  @javac --release 11 -d .out/tmp/java .out/wrap/java/com/turtledsr/hazemodlib/*.java
  @jar -cvf .out/lib/java/hazemodlib.jar -C .out/tmp/java/ .

  @#CSHARP
  @[ -d .out/lib/csharp/ ] || mkdir -p .out/lib/csharp/
  @[ -d .out/tmp/csharp/ ] || mkdir -p .out/tmp/csharp/
  @dotnet new classlib -o .out/tmp/csharp/HazeModLib_CS --name HazeModLib_CS --force
  @rm .out/tmp/csharp/HazeModLib_CS/Class1.cs
  @cp -r .out/wrap/csharp/*.cs .out/tmp/csharp/HazeModLib_CS/
  @cp zig-out/bin/haze_mod_lib_csharp.dll .out/lib/csharp/HazeModLib.dll
  @dotnet build .out/tmp/csharp/HazeModLib_CS/HazeModLib_CS.csproj -c Release
  @cp .out/tmp/csharp/HazeModLib_CS/bin/Release/net10.0/HazeModLib_CS.dll .out/lib/csharp/HazeModLib_CS.dll

  @#PYTHON
  @[ -d .out/lib/python/ ] || mkdir -p .out/lib/python/
  @cp .out/wrap/python/haze_mod_lib.py .out/lib/python/
  @cp zig-out/bin/haze_mod_lib_python.dll .out/lib/python/_haze_mod_lib.pyd

test-c: release
  @[ -d .out/c/test/ ] || mkdir -p .out/c/test/
  @cp .out/lib/c/haze_mod_lib.h test/c/include/
  @cp .out/lib/c/haze_mod_lib.lib test/c/include/
  @cp zig-out/bin/haze_mod_lib.dll .out/c/test/
  @clang -std=c23 -O0 test/c/test.c -o .out/c/test/test.exe -Itest/c/include/ -Ltest/c/include/ -lhaze_mod_lib
  @.out/c/test/test.exe

test-py: release
  @cp .out/lib/python/haze_mod_lib.py test/py/lib/
  @cp .out/lib/python/_haze_mod_lib.pyd test/py/lib/
  @py test/py/test.py

test-j: release
  @[ -d .out/tmp/javatest/ ] || mkdir -p .out/tmp/javatest/
  @cp .out/lib/java/hazemodlib.jar test/java/lib/

  @cp .out/lib/java/haze_mod_lib.dll .out/tmp/javatest/
  @cp .out/lib/java/hazemodlib.jar .out/tmp/javatest/
  @javac --release 11 -d .out/tmp/javatest/src/ -cp "test/java/lib/hazemodlib.jar" test/java/*.java
  @cd .out/tmp/javatest/ && java --enable-native-access=ALL-UNNAMED -cp "src;hazemodlib.jar" test.java.Main

test-cs: release
  @cp .out/lib/csharp/HazeModLib_CS.dll test/cs/lib/
  @cp .out/lib/csharp/HazeModLib.dll test/cs/lib/
  @dotnet build test/cs/test.csproj -c Release
  ./test/cs/bin/Release/net10.0/test.exe
