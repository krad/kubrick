public enum Position {
    case unspecified
    case front
    case back
}

public enum MediaType {
    case video
    case audio
}

public protocol Source {
    var uniqueID: String { get }
    var isConnected: Bool { get }
    var modelID: String { get }
    var localizedName: String { get }
    var type: MediaType? { get }
}

#if os(macOS) || os(iOS)
import AVFoundation
    extension AVCaptureDevice: Source {
        public var type: MediaType? {
            if self.hasMediaType(AVMediaType.audio) {
                return .audio
            }
            
            if self.hasMediaType(.video) {
                return .video
            }
            
            return nil
        }
    }
#endif
