release:
  just lib x86_64-windows-gnu
  just lib aarch64-linux-gnu

build target='native':
  @clear
  @zig build -Dtarget={{target}}

bind target='native': (build target)
  #!/usr/bin/env bash
  rm -rf zig-out/
  rm -rf .out/lib/
  rm -rf .out/wrap/

  zig build bind -Dtarget={{target}}
  

  [ -d .out/wrap/java/com/turtledsr/hazemodlib ] || mkdir -p .out/wrap/java/com/turtledsr/hazemodlib
  [ -d .out/wrap/csharp/ ] || mkdir -p .out/wrap/csharp/
  [ -d .out/wrap/python/ ] || mkdir -p .out/wrap/python/
  [ -d .out/wrap/go/ ] || mkdir -p .out/wrap/go/

  #C
  if [ -f "zig-out/lib/haze_mod_lib_static.lib" ]; then
    lib_pre=""
    lib_ext="lib"
  else
    lib_ext="a"
    lib_pre="lib"
  fi

  cp "zig-out/lib/${lib_pre}haze_mod_lib_static.$lib_ext" "bind/include/${lib_pre}haze_mod_lib.$lib_ext"
  cp "zig-pkg/zip-1.1.1-17qA5SeETAARZp54FPuYDDo8xmIyw95VVyVTbSlg8sx7/lib/${lib_pre}zip_c.$lib_ext" "bind/include/${lib_pre}zip_c.$lib_ext"

  #JAVA
  swig -java -c++ -package com.turtledsr.hazemodlib -outdir .out/wrap/java/com/turtledsr/hazemodlib -o .out/wrap/java/haze_mod_lib_wrap.cxx bind/haze_mod_lib.i
  rm .out/wrap/java/com/turtledsr/hazemodlib/HazeModLib.java

  #CSHARP
  swig -csharp -c++ -namespace Com.Turtledsr.HazeModLib -outdir .out/wrap/csharp -o .out/wrap/csharp/haze_mod_lib_wrap.cxx bind/haze_mod_lib.i
  rm .out/wrap/csharp/HazeModLib.cs

  #PYTHON
  swig -python -c++ -outdir .out/wrap/python -o .out/wrap/python/haze_mod_lib_wrap.cxx bind/haze_mod_lib.i

lint: build
  @zig build lint

test: build
  @[ -d test/static/sandbox/Script ] || mkdir -p test/static/sandbox/Script
  @zig build test --summary all

lib target='native': (bind target)
  #!/usr/bin/env bash
  if [ -f "zig-out/lib/haze_mod_lib_static.lib" ]; then
    lib_pre=""
    lib_ext="lib"
    dynamic_dir="bin"
    dynamic_ext="dll"
  else
    dynamic_dir="lib"
    dynamic_ext="so"
    lib_ext="so"
    lib_pre="lib"
  fi

  #C
  [ -d .out/lib/c/ ] || mkdir -p .out/lib/c/
  cp bind/haze_mod_lib.h .out/lib/c/
  cp zig-out/lib/${lib_pre}haze_mod_lib.$lib_ext .out/lib/c/
  [ -f "zig-out/bin/haze_mod_lib.dll" ] && cp zig-out/bin/haze_mod_lib.dll .out/lib/c/

  #build all swig dll's
  zig build release -Dtarget={{target}}

  #JAVA
  [ -d .out/lib/java/ ] || mkdir -p .out/lib/java/
  cp zig-out/${dynamic_dir}/${lib_pre}haze_mod_lib_java.${dynamic_ext} .out/lib/java/haze_mod_lib.${dynamic_ext}
  javac --release 11 -d .out/tmp/java .out/wrap/java/com/turtledsr/hazemodlib/*.java
  jar -cvf .out/lib/java/hazemodlib.jar -C .out/tmp/java/ .

  #CSHARP
  [ -d .out/lib/csharp/ ] || mkdir -p .out/lib/csharp/
  [ -d .out/tmp/csharp/ ] || mkdir -p .out/tmp/csharp/
  dotnet new classlib -o .out/tmp/csharp/HazeModLib_CS --name HazeModLib_CS --force
  rm .out/tmp/csharp/HazeModLib_CS/Class1.cs
  cp -r .out/wrap/csharp/*.cs .out/tmp/csharp/HazeModLib_CS/
  cp zig-out/${dynamic_dir}/${lib_pre}haze_mod_lib_csharp.${dynamic_ext} .out/lib/csharp/${lib_pre}HazeModLib.${dynamic_ext}
  dotnet build .out/tmp/csharp/HazeModLib_CS/HazeModLib_CS.csproj -c Release
  cp .out/tmp/csharp/HazeModLib_CS/bin/Release/net10.0/HazeModLib_CS.dll .out/lib/csharp/HazeModLib_CS.dll

  #PYTHON
  [ -d .out/lib/python/ ] || mkdir -p .out/lib/python/
  cp .out/wrap/python/haze_mod_lib.py .out/lib/python/
  cp zig-out/${dynamic_dir}/${lib_pre}haze_mod_lib_python.${dynamic_ext} .out/lib/python/_haze_mod_lib.pyd

  #GO
  [ -d .out/lib/go/ ] || mkdir -p .out/lib/go/
  [ -d go/ ] || mkdir -p go/

  cp zig-out/${dynamic_dir}/${lib_pre}haze_mod_lib_go.${dynamic_ext} .out/lib/go/

  cp zig-out/${dynamic_dir}/${lib_pre}haze_mod_lib_go.${dynamic_ext} go/
  cp zig-out/lib/${lib_pre}haze_mod_lib_go.$lib_ext go/

  #PACKAGE
  [ -d .out/package/ ] || mkdir -p .out/package/
  ./zip .out/lib/ .out/package/hazemodlib-{{target}}.zip

test-c: lib
  #!/usr/bin/env bash
  if [ -f "zig-out/lib/haze_mod_lib_static.lib" ]; then
    lib_pre=""
    lib_ext="lib"
  else
    lib_ext="so"
    lib_pre="lib"
  fi

  [ -d .out/c/test/ ] || mkdir -p .out/c/test/
  cp .out/lib/c/haze_mod_lib.h test/c/include/
  cp .out/lib/c/${lib_pre}haze_mod_lib.$lib_ext test/c/include/
  cp zig-out/${dynamic_dir}/${lib_pre}haze_mod_lib.$lib_ext .out/c/test/
  clang -std=c23 -O0 test/c/test.c -o .out/c/test/test.exe -Itest/c/include/ -Ltest/c/include/ -lhaze_mod_lib
  .out/c/test/test.exe

test-py: lib
  @cp .out/lib/python/haze_mod_lib.py test/py/lib/
  @cp .out/lib/python/_haze_mod_lib.pyd test/py/lib/
  @py test/py/test.py

test-j: lib
  @[ -d .out/tmp/javatest/ ] || mkdir -p .out/tmp/javatest/
  @cp .out/lib/java/hazemodlib.jar test/java/lib/

  @cp .out/lib/java/haze_mod_lib.dll .out/tmp/javatest/
  @cp .out/lib/java/hazemodlib.jar .out/tmp/javatest/
  @javac --release 11 -d .out/tmp/javatest/src/ -cp "test/java/lib/hazemodlib.jar" test/java/*.java
  @cd .out/tmp/javatest/ && java --enable-native-access=ALL-UNNAMED -cp "src;hazemodlib.jar" test.java.Main

test-cs: lib
  @cp .out/lib/csharp/HazeModLib_CS.dll test/cs/lib/
  @cp .out/lib/csharp/HazeModLib.dll test/cs/lib/
  @dotnet build test/cs/test.csproj -c Release
  @./test/cs/bin/Release/net10.0/test.exe

test-go: lib
  @cp go/haze_mod_lib_go.dll test/go/
  @cd test/go/ && go run -race main.go
