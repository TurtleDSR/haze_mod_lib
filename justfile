cflags := "-std=c23 -O3"

build:
  @clear
  @zig build

bind: build
  @clear
  @zig build bind

  @rm -r .out/wrap/

  @[ -d .out/wrap/java/com/turtledsr/hazemodlib ] || mkdir -p .out/wrap/java/com/turtledsr/hazemodlib
  @cp zig-out/lib/haze_mod_lib.lib bind/include/
  @cp zig-pkg/zip-1.0.4-17qA5UcTHwB6CVYazmkLoacjgUas9NAwGmxVtmy7wEBx/lib/zip_c.lib bind/include/zip_c.lib

  swig -java -package com.turtledsr.hazemodlib -outdir .out/wrap/java/com/turtledsr/hazemodlib -o .out/wrap/java/haze_mod_lib_wrap.c bind/haze_mod_lib.i
  @rm .out/wrap/java/com/turtledsr/hazemodlib/HazeModLib.java

lint: build
  @clear
  @zig build lint

test: build
  @clear
  @[ -d test/static/sandbox/Script ] || mkdir -p test/static/sandbox/Script
  @#@unzip -o test/static/sandbox/scripts.zip -d test/static/sandbox/Script/
  @zig build test --summary all

build-c: bind #c build script
  @[ -d .out/c/test/ ] || mkdir -p .out/c/test/
  @cp bind/haze_mod_lib.h test/c/include/
  @cp zig-out/lib/haze_mod_lib.lib test/c/include/
  @cp zig-out/bin/haze_mod_lib.dll .out/c/test/

test-c: build-c
  clang -std=c23 -O0 test/c/test.c -o .out/c/test/test.exe -Itest/c/include/ -Ltest/c/include/ -lhaze_mod_lib
  .out/c/test/test.exe

build-j: bind #java build script
  @[ -d .out/tmp/java/ ] || mkdir -p .out/tmp/java/

  clang {{cflags}} -DDLLBUILD -c .out/wrap/java/haze_mod_lib_wrap.c -Ibind/include/jni/ -Ibind/ -o .out/tmp/java/haze_mod_lib_wrap.o

  @[ -d .out/lib/java/ ] || mkdir -p .out/lib/java/
  clang {{cflags}} -shared -o .out/lib/java/haze_mod_lib.dll .out/tmp/java/*.o -Lbind/include/ -lhaze_mod_lib

  rm .out/lib/java/haze_mod_lib.exp
  rm .out/lib/java/haze_mod_lib.lib

  javac -parameters --release 11 -d .out/tmp/java/jar .out/wrap/java/com/turtledsr/hazemodlib/*.java
  jar -cvf .out/lib/java/hazemodlib.jar -C .out/tmp/java/jar .

release: build-c build-j
  @[ -d .out/lib/c/ ] || mkdir -p .out/lib/c/
  @cp bind/haze_mod_lib.h .out/lib/c/
  @cp zig-out/lib/haze_mod_lib.lib .out/lib/c/
  @cp zig-out/bin/haze_mod_lib.dll .out/lib/c/
