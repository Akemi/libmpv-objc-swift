#import <OpenGL/gl.h>
#import <stdio.h>
#import <stdlib.h>

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>



@interface Layer : CAOpenGLLayer {
    float red;
    float green;
    float blue;

    float redSin;
    float greenSin;
    float blueSin;
}
@end

@implementation Layer

- (id)init
{
    if (self = [super init]) {
        [self setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
        [self setBackgroundColor:[NSColor blackColor].CGColor];
        [self setAsynchronous:YES];

        red = 0.0;
        green = 0.0;
        blue = 0.0;

        redSin = 0.0;
        greenSin = 0.0;
        blueSin = 0.0;
    }
    return self;
}

- (BOOL)canDrawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf
        forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    return YES;
}

- (void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf
        forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    glClearColor(redSin, greenSin, blueSin, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    CGLFlushDrawable(ctx);

    red += 0.005;
    green += 0.008;
    blue += 0.01;

    redSin = fabs(sin(red * M_PI));
    greenSin = fabs(sin(green * M_PI));
    blueSin = fabs(sin(blue * M_PI));
}

- (CGLPixelFormatObj)copyCGLPixelFormatForDisplayMask:(uint32_t)mask
{
    CGLPixelFormatAttribute attrs[] = {
        kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute) kCGLOGLPVersion_3_2_Core,
        kCGLPFADoubleBuffer,
        kCGLPFAAllowOfflineRenderers,
        kCGLPFABackingStore,
        kCGLPFAAccelerated,
        kCGLPFASupportsAutomaticGraphicsSwitching,
        0
    };

    GLint npix;
    CGLPixelFormatObj pix;
    CGLChoosePixelFormat(attrs, &pix, &npix);

    return pix;
}

- (CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf
{
    CGLContextObj ctx = [super copyCGLContextForPixelFormat:pf];

    GLint i = 1;
    CGLSetParameter(ctx, kCGLCPSwapInterval, &i);
    CGLEnable(ctx, kCGLCEMPEngine);
    CGLSetCurrentContext(ctx);
    return ctx;
}
@end

@interface Window : NSWindow <NSWindowDelegate> {
    Layer *layer;
}
@end

@implementation Window

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSWindowStyleMask)style
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag
{
    if (self = [super initWithContentRect:contentRect
                                styleMask:style
                                  backing:bufferingType
                                    defer:flag]) {
        [self setTitle:@"test"];
        [self setMinSize:NSMakeSize(200, 200)];
        [self makeMainWindow];
        [self makeKeyAndOrderFront:nil];
        self.delegate = self;

        self.contentAspectRatio = self.contentView.frame.size;

        layer = [[Layer alloc] init];
        [self.contentView setLayer:layer];
        self.contentView.wantsLayer = YES;
    }
    return self;
}

- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }


@end
