build:
  @clear
  @zig build

lint: build
  @clear
  @zig build lint

test: build
  @clear
  @[ -d test/static/sandbox/Scripts ] || mkdir -p test/static/sandbox/Scripts
  @#@unzip -o test/static/sandbox/scripts.zip -d test/static/sandbox/Scripts/
  @zig build test --summary all

release: