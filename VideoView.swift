import Cocoa

class VideoView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame:frameRect)
        autoresizingMask = [.width, .height]
        wantsBestResolutionOpenGLSurface = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}