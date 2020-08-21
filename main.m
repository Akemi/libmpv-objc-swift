/*

mkdir build
swift -frontend -c -sdk `xcrun --sdk macosx --show-sdk-path` -enable-objc-interop -emit-objc-header -emit-objc-header-path build/macos_swift.h -import-objc-header bridging-header.h -c -o build/VideoWindow.o VideoWindow.swift VideoLayer.swift VideoView.swift `pkg-config --libs --cflags mpv`
clang -isysroot `xcrun --sdk macosx --show-sdk-path` -c -I . main.m `pkg-config --cflags mpv` -DGL_SILENCE_DEPRECATION -o build/main.o
clang -isysroot `xcrun --sdk macosx --show-sdk-path` -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx -o test build/main.o build/VideoWindow.o `pkg-config --libs --cflags mpv` -Xlinker -rpath -Xlinker /usr/lib/swift -L/usr/lib/swift

*/



#import <Cocoa/Cocoa.h>
#import "build/macos_swift.h"



@interface AppDelegate : NSObject <NSApplicationDelegate> {
    VideoWindow *vwindow;
}
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    atexit_b(^{
        [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    });

    int mask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
               NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;

    vwindow =
        [[VideoWindow alloc] initWithContentRect:NSMakeRect(300, 300, 1280, 720)
                                       styleMask:mask
                                         backing:NSBackingStoreBuffered
                                           defer:NO];

    [NSApp setMenu:[self mainMenu]];

    [NSApp activateIgnoringOtherApps:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app
{
    return YES;
}

- (NSMenu *)mainMenu
{
    NSMenu *m = [[NSMenu alloc] initWithTitle:@"AMainMenu"];
    NSMenuItem *item = [m addItemWithTitle:@"Apple" action:nil keyEquivalent:@""];
    NSMenu *sm = [[NSMenu alloc] initWithTitle:@"Apple"];
    [m setSubmenu:sm forItem:item];

    [sm addItemWithTitle:@"Fullscreen" action:@selector(fullscreen) keyEquivalent:@"f"];
    [sm addItemWithTitle:@"Quit" action:@selector(quit) keyEquivalent:@"q"];

    return m;
}

@end


int main(int argc, const char *argv[])
{
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [AppDelegate new];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
