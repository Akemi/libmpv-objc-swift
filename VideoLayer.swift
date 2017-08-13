import Cocoa
import OpenGL.GL
import OpenGL.GL3


func getProcAddress(_ ctx: UnsafeMutableRawPointer?,
                    _ name: UnsafePointer<Int8>?) -> UnsafeMutableRawPointer? {
    let symbol: CFString = CFStringCreateWithCString(
                            kCFAllocatorDefault, name, kCFStringEncodingASCII)
    let indentifier = CFBundleGetBundleWithIdentifier("com.apple.opengl" as CFString)
    let addr = CFBundleGetFunctionPointerForName(indentifier, symbol)

    if addr == nil {
        print("Cannot get OpenGL function pointer!")
    }
    return addr
}

func updateCallback(_ ctx: UnsafeMutableRawPointer?) {
    let videoLayer = unsafeBitCast(ctx, to: VideoLayer.self)
    videoLayer.queue.async {
        if !videoLayer.isAsynchronous {
            videoLayer.display()
        }
    }
}

class VideoLayer: CAOpenGLLayer {

    var mpv: OpaquePointer?
    var mpvGLCBContext: OpaquePointer?
    var surfaceSize: NSSize?
    var link: CVDisplayLink?
    var queue: DispatchQueue = DispatchQueue(label: "io.mpv.callbackQueue")

    private var _inLiveResize: Bool?
    var inLiveResize: Bool {
        set(live) {
            _inLiveResize = live
            if _inLiveResize == false {
                isAsynchronous = false
                queue.async{ self.display() }
            } else {
                isAsynchronous = true
            }
        }
        get {
            return _inLiveResize!
        }
    }

    override init() {
        super.init()
        autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        backgroundColor = NSColor.black.cgColor
        _inLiveResize = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func canDraw(inCGLContext ctx: CGLContextObj,
                          pixelFormat pf: CGLPixelFormatObj,
                          forLayerTime t: CFTimeInterval,
                          displayTime ts: UnsafePointer<CVTimeStamp>?) -> Bool {
        return true
    }

    override func draw(inCGLContext ctx: CGLContextObj,
                       pixelFormat pf: CGLPixelFormatObj,
                       forLayerTime t: CFTimeInterval,
                       displayTime ts: UnsafePointer<CVTimeStamp>?) {
        var i: GLint = 0
        glGetIntegerv(GLenum(GL_DRAW_FRAMEBUFFER_BINDING), &i)

        if mpvGLCBContext != nil {
            if inLiveResize == false {
                surfaceSize = self.bounds.size
            }
            mpv_opengl_cb_draw(mpvGLCBContext, i, Int32(surfaceSize!.width), Int32(-surfaceSize!.height))
        } else {
            glClearColor(0, 0, 0, 1)
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT ))
        }

        CGLFlushDrawable(ctx)
    }

    override func copyCGLPixelFormat(forDisplayMask mask: UInt32) -> CGLPixelFormatObj {
        let attrs: [CGLPixelFormatAttribute] = [
            kCGLPFAOpenGLProfile, CGLPixelFormatAttribute(kCGLOGLPVersion_3_2_Core.rawValue),
            kCGLPFADoubleBuffer,
            kCGLPFAAllowOfflineRenderers,
            kCGLPFABackingStore,
            kCGLPFAAccelerated,
            kCGLPFASupportsAutomaticGraphicsSwitching,
            _CGLPixelFormatAttribute(rawValue: 0)
        ]

        var npix: GLint = 0
        var pix: CGLPixelFormatObj?
        CGLChoosePixelFormat(attrs, &pix, &npix)

        return pix!
    }

    override func copyCGLContext(forPixelFormat pf: CGLPixelFormatObj) -> CGLContextObj {
        let ctx = super.copyCGLContext(forPixelFormat:pf)

        var i: GLint = 1
        CGLSetParameter(ctx, kCGLCPSwapInterval, &i)
        CGLEnable(ctx, kCGLCEMPEngine)
        CGLSetCurrentContext(ctx)

        initMPV()
        initDisplayLink()

        return ctx
    }

    override func display() {
        super.display()
        CATransaction.flush()
    }

    func initMPV() {
        let args = CommandLine.arguments
        if (args.count < 2) {
            print("Expected filename on command line")
            exit(1)
        }
        let filename = args[1]

        mpv = mpv_create()
        if mpv == nil {
            print("failed creating context")
            exit(1)
        }

        checkError(mpv_set_option_string(mpv, "terminal", "yes"))
        checkError(mpv_set_option_string(mpv, "input-media-keys", "yes"))
        checkError(mpv_set_option_string(mpv, "input-ipc-server", "/tmp/mpvsocket"))
        checkError(mpv_set_option_string(mpv, "input-default-bindings", "yes"))
        checkError(mpv_set_option_string(mpv, "config", "yes"))
        //checkError(mpv_set_option_string(mpv, "msg-level", "all=v"))
        checkError(mpv_set_option_string(mpv, "config-dir", NSHomeDirectory()+"/.config/mpv"))
        checkError(mpv_set_option_string(mpv, "vo", "opengl-cb"))
        checkError(mpv_set_option_string(mpv, "display-fps", "60"))

        checkError(mpv_initialize(mpv))

        mpvGLCBContext = OpaquePointer(mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB))
        if mpvGLCBContext == nil {
            print("libmpv does not have the opengl-cb sub-API.")
            exit(1)
        }

        let r = mpv_opengl_cb_init_gl(mpvGLCBContext, nil, getProcAddress, nil)
        if r < 0 {
            print("gl init has failed.")
            exit(1)
        }

        mpv_opengl_cb_set_update_callback(mpvGLCBContext, updateCallback,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

        mpv_set_wakeup_callback(mpv, { (ctx) in
            let mpvController = unsafeBitCast(ctx, to: VideoLayer.self)
            mpvController.readEvents()
        }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

        queue.async {
            let cmd = ["loadfile", filename, nil]
            var args = cmd.map{$0.flatMap{UnsafePointer<Int8>(strdup($0))}}
            self.checkError(mpv_command(self.mpv, &args))
        }
    }

    func uninitMPV() {
        let cmd = ["quit", nil]
        var args = cmd.map{$0.flatMap{UnsafePointer<Int8>(strdup($0))}}
        mpv_command(mpv, &args)
    }

    private func readEvents() {
        queue.async {
            while self.mpv != nil {
                let event = mpv_wait_event(self.mpv, 0)
                if event!.pointee.event_id == MPV_EVENT_NONE {
                    break
                }
                self.handleEvent(event)
            }
        }
    }

    func handleEvent(_ event: UnsafePointer<mpv_event>!) {
        switch event.pointee.event_id {
        case MPV_EVENT_SHUTDOWN:
            mpv_opengl_cb_uninit_gl(mpvGLCBContext)
            mpvGLCBContext = nil
            mpv_detach_destroy(mpv)
            mpv = nil
            NSApp.terminate(self)
        case MPV_EVENT_LOG_MESSAGE:
            let logmsg = UnsafeMutablePointer<mpv_event_log_message>(OpaquePointer(event.pointee.data))
            print("log:", String(cString: (logmsg!.pointee.prefix)!),
                          String(cString: (logmsg!.pointee.level)!),
                          String(cString: (logmsg!.pointee.text)!))
        default:
            print("event:", String(cString: mpv_event_name(event.pointee.event_id)))
        }
    }

    let displayLinkCallback: CVDisplayLinkOutputCallback = { (displayLink, now, outputTime, flagsIn, flagsOut, displayLinkContext) -> CVReturn in
        let layer: VideoLayer = unsafeBitCast(displayLinkContext, to: VideoLayer.self)
        if layer.mpvGLCBContext != nil {
            mpv_opengl_cb_report_flip(layer.mpvGLCBContext, 0)
        }
        return kCVReturnSuccess
    }

    func initDisplayLink() {
        let displayId = UInt32(NSScreen.main()!.deviceDescription["NSScreenNumber"] as! Int)

        CVDisplayLinkCreateWithCGDisplay(displayId, &link)
        CVDisplayLinkSetOutputCallback(link!, displayLinkCallback,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        CVDisplayLinkStart(link!)
    }

    func uninitDisplaylink() {
        if CVDisplayLinkIsRunning(link!) {
            CVDisplayLinkStop(link!)
        }
    }

    func checkError(_ status: CInt) {
        if (status < 0) {
            print("mpv API error:", mpv_error_string(status))
            exit(1)
        }
    }
}