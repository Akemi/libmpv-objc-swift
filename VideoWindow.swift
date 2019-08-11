import Cocoa

class VideoWindow: NSWindow, NSWindowDelegate {

    var vlayer: VideoLayer?
    var vview: VideoView?
    var windowFrame: NSRect?

    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect:contentRect, styleMask:style, backing:backingStoreType, defer:flag)

        title = "test"
        minSize = NSMakeSize(200, 200)
        makeMain()
        makeKeyAndOrderFront(nil)
        delegate = self

        contentAspectRatio = contentView!.frame.size
        windowFrame = convertToScreen(contentView!.frame)

        vview = VideoView(frame: contentView!.bounds)
        contentView!.addSubview(vview!)

        vlayer = VideoLayer()
        vview!.layer = vlayer
        vview!.wantsLayer = true
    }

    func windowWillStartLiveResize(_ notification: Notification) {
        vlayer!.inLiveResize = true
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        vlayer!.inLiveResize = false
    }

    func customWindowsToEnterFullScreen(for window: NSWindow) -> [NSWindow]? {
        return [window]
    }

    func customWindowsToExitFullScreen(for window: NSWindow) -> [NSWindow]? {
        return [window]
    }

    func window(_ window: NSWindow, startCustomAnimationToEnterFullScreenWithDuration duration: TimeInterval) {
        windowFrame = convertToScreen(contentView!.frame)
        NSAnimationContext.runAnimationGroup({ (context) -> Void in
            context.duration = duration*0.9
            window.animator().setFrame(screen!.frame, display: true)
        }, completionHandler: { })
    }

    func window(_ window: NSWindow, startCustomAnimationToExitFullScreenWithDuration duration: TimeInterval) {
        NSAnimationContext.runAnimationGroup({ (context) -> Void in
            context.duration = duration*0.9
            window.animator().setFrame(windowFrame!, display: true)
        }, completionHandler: { })
    }

    func windowDidEnterFullScreen(_ notification: Notification) {}

    func windowDidExitFullScreen(_ notification: Notification) {
        contentAspectRatio = windowFrame!.size
    }

    func windowDidFailToEnterFullScreen(_ window: NSWindow) {}

    func windowDidFailToExitFullScreen(_ window: NSWindow) {}

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        vlayer!.uninitMPV()
        return false
    }
}