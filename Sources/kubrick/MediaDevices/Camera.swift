public class Camera: MediaDevice {
    
    public var source: Source
    public var input: MediaDeviceInput?
    public var output: MediaDeviceOutput?
    public var reader: MediaDeviceReader?
    
    public var frameRate: Float64 {
        didSet { self.update(frameRate: self.frameRate) }
    }
    
    public var orientation: CameraOrientation = .unknown {
        didSet { self.update(orientation: self.orientation) }
    }
    
    public init(_ source: Source) {
        self.source     = source
        self.frameRate  = 30
        self.update(frameRate: self.frameRate)
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
    #if os(iOS)
        import UIKit
    #endif
    
    extension Camera {
        func update(frameRate: Float64) {
            print("=========", #function, "Updating frame rate", frameRate)
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
                    if conn.isVideoOrientationSupported {
                        switch orientation {
                        case .portrait:
                            conn.videoOrientation = .portrait
                        case .landscapeRight :
                            conn.videoOrientation = .landscapeRight
                        case .landscapeLeft:
                            conn.videoOrientation = .landscapeLeft
                        case .upsideDown:
                            conn.videoOrientation = .portraitUpsideDown
                        default:
                            conn.videoOrientation = .portrait
                        }
                    }
                }
            }
        }
        
        #if os(iOS)
        public func set(orientation: UIInterfaceOrientation) {
            switch orientation {
                case .landscapeLeft:
                    self.orientation = .landscapeRight
                case .landscapeRight:
                    self.orientation = .landscapeLeft
                case .portrait:
                    self.orientation = .portrait
                case .portraitUpsideDown:
                    self.orientation = .upsideDown
                default:
                    self.orientation = .portrait
            }
        }
        #endif
        
    }
    
    #if os(iOS)
    extension UIInterfaceOrientation {
        public var avOrientation: AVCaptureVideoOrientation {
            switch self {
            case .landscapeRight:
                return .landscapeRight
            case .landscapeLeft:
                return .landscapeLeft
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            default:
                return .portrait
            }
        }
    }
    #endif
    
#endif
