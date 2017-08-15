## Build

```
swift -frontend -c -sdk `xcrun --sdk macosx --show-sdk-path` -enable-objc-interop -emit-objc-header -emit-objc-header-path VideoWindow.h -import-objc-header bridging-header.h -c -o VideoWindow.o VideoWindow.swift VideoLayer.swift VideoView.swift `pkg-config --libs --cflags mpv`
clang -isysroot `xcrun --sdk macosx --show-sdk-path` -c -I . main.m `pkg-config --cflags mpv`
clang -isysroot `xcrun --sdk macosx --show-sdk-path` -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift_static/macosx -Xlinker -force_load_swift_libs -lc++ -o test main.o VideoWindow.o `pkg-config --libs --cflags mpv`
```

## Usage

```
./test file.mkv
```

## Info

This is just a small libmpv test with a CAOpenGLLayer. It shows how to interact with Swift with an Objective-C main and an NSApplicationDelegate.
