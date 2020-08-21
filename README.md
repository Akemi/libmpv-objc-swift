## Build

```
mkdir build
swift -frontend -c -sdk `xcrun --sdk macosx --show-sdk-path` -enable-objc-interop -emit-objc-header -emit-objc-header-path build/macos_swift.h -import-objc-header bridging-header.h -c -o build/VideoWindow.o VideoWindow.swift VideoLayer.swift VideoView.swift `pkg-config --libs --cflags mpv`
clang -isysroot `xcrun --sdk macosx --show-sdk-path` -c -I . main.m `pkg-config --cflags mpv` -DGL_SILENCE_DEPRECATION -o build/main.o
clang -isysroot `xcrun --sdk macosx --show-sdk-path` -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx -o test build/main.o build/VideoWindow.o `pkg-config --libs --cflags mpv` -Xlinker -rpath -Xlinker /usr/lib/swift -L/usr/lib/swift
```

## Usage

```
./test file.mkv
```

## Info

This is just a small libmpv test with a CAOpenGLLayer. It shows how to interact
with Swift with an Objective-C main and an NSApplicationDelegate.
