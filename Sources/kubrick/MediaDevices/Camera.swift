public class Camera: MediaDevice {
    
    public var source: Source
    public var input: MediaDeviceInput?
    public var output: MediaDeviceOutput?
    public var reader: MediaDeviceReader?
    
    public var frameRate: Float64 = 24.0 {
        didSet { self.update(frameRate: self.frameRate) }
    }
    
    public var orientation: CameraOrientation = .unknown {
        didSet { self.update(orientation: self.orientation) }
    }
    
    public init(_ source: Source) {
        self.source = source
    }
    
}

public enum CameraOrientation {
    case portrait
    case landscapeLeft
    case landscapeRight
    case upsideDown
    case unknown
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
                } catch let err {
                    print("Could not configure framerate:", err)
                }
            }
        }
        
        func update(orientation: CameraOrientation) {
            if let out = self.output as? AVCaptureVideoDataOutput {
                if let conn = out.connection(with: .video) {
                    switch orientation {
                    case .portrait:
                        conn.videoOrientation = .portrait
                    case .landscapeRight :
                        conn.videoOrientation = .landscapeLeft
                    case .landscapeLeft:
                        conn.videoOrientation = .landscapeRight
                    case .upsideDown:
                        conn.videoOrientation = .portraitUpsideDown
                    default:
                        conn.videoOrientation = .portrait
                    }
                }
            }
        }
    }
    
#endif
