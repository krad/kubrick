public class Camera: MediaDevice {
    
    public var source: Source
    public var input: MediaDeviceInput?
    public var output: MediaDeviceOutput?
    public var reader: MediaDeviceReader?
    
    public var frameRate: Float64 = 24.0 {
        didSet { self.update(frameRate: self.frameRate) }
    }
    
    public init(_ source: Source) {
        self.source = source
    }
    
}


#if os(macOS) || os(iOS)
    import AVFoundation
    
    extension Camera {
        func update(frameRate: Float64) {
            if let src = self.source as? AVCaptureDevice {
                do {
                    try src.lockForConfiguration()
                    let fps                         = CMTimeMake(1, Int32(frameRate))
                    src.activeVideoMinFrameDuration = fps
                    src.activeVideoMaxFrameDuration = fps
                    src.unlockForConfiguration()

                    if let o = self.output as? AVCaptureVideoDataOutput {
                        o.connections.first?.videoMinFrameDuration = fps
                        o.connections.first?.videoMaxFrameDuration = fps
                    }
                    
                } catch let err {
                    print("Could not configure framerate:", err)
                }
            }
        }
    }
    
#endif
