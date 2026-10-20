build:
  @clear
  @zig build

bind: build
  @clear
  @zig build bind

lint: build
  @clear
  @zig build lint

test: build
  @clear
  @[ -d test/static/sandbox/Script ] || mkdir -p test/static/sandbox/Script
  @#@unzip -o test/static/sandbox/scripts.zip -d test/static/sandbox/Script/
  @zig build test --summary all

build-c: bind
  @[ -d .out/c/test/ ] || mkdir -p .out/c/test/
  @cp bind/haze_mod_lib.h test/c/include/
  @cp zig-out/lib/haze_mod_lib.lib test/c/include/
  @cp zig-out/bin/haze_mod_lib.dll .out/c/test/

  clang -std=c23 -O0 test/c/test.c -o .out/c/test/test.exe -Itest/c/include/ -Ltest/c/include/ -lhaze_mod_lib

test-c: build-c
  .out/c/test/test.exe

release: build-c
  @[ -d .out/lib/c/ ] || mkdir -p .out/lib/c/
  @cp bind/haze_mod_lib.h .out/lib/c/
  @cp zig-out/lib/haze_mod_lib.lib .out/lib/c/
  @cp zig-out/bin/haze_mod_lib.dll .out/lib/c/
