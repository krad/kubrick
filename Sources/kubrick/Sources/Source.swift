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
    var deviceFormats: [DeviceFormat] { get }
}

public protocol DeviceFormat {
    var type: SampleType { get }
    var frameRates: [FrameRateRange] { get }
}

#if os(macOS) || os(iOS)
import AVFoundation
    extension AVCaptureDevice: Source {
        
        public var type: MediaType? {
            if self.hasMediaType(.audio) { return .audio }
            if self.hasMediaType(.video) { return .video }
            return nil
        }
        
        public var deviceFormats: [DeviceFormat] {
            return self.formats
        }
    }
    
    extension AVCaptureDevice.Format: DeviceFormat {
        
        public var type: SampleType {
            if let t = SampleType(rawValue: self.mediaType.rawValue) {
                return t
            }
            return .unknown
        }
        
        public var frameRates: [FrameRateRange] {
            return self.videoSupportedFrameRateRanges
        }
        
    }
#endif
