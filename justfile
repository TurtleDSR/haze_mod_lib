build:
  @clear
  @zig build

bind: build
  @clear
  @zig build bind

  @rm -rf .out/wrap/

  @[ -d .out/wrap/java/com/turtledsr/hazemodlib ] || mkdir -p .out/wrap/java/com/turtledsr/hazemodlib
  @cp zig-out/lib/haze_mod_lib_static.lib bind/include/haze_mod_lib.lib
  @cp zig-pkg/zip-1.0.4-17qA5UcTHwB6CVYazmkLoacjgUas9NAwGmxVtmy7wEBx/lib/zip_c.lib bind/include/zip_c.lib

  swig -java -c++ -package com.turtledsr.hazemodlib -outdir .out/wrap/java/com/turtledsr/hazemodlib -o .out/wrap/java/haze_mod_lib_wrap.cxx bind/haze_mod_lib.i
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
