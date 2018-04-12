public protocol VideoEncoderSettings {}

public struct H264Settings {
    
    public var profile: H264ProfileLevel
    public var frameRate: Float
    public var width: Int
    public var height: Int
    public var maxBitRate: Int
    
    public init(profile: H264ProfileLevel = .h264Baseline_3_0,
                frameRate: Float = 25.0,
                width: Int = 400,
                height: Int = 224,
                maxBitRate: Int = 110_000)
    {
        self.profile    = profile
        self.frameRate  = frameRate
        self.width      = width
        self.height     = height
        self.maxBitRate = maxBitRate
    }
}

public enum H264ProfileLevel {
    case h264Baseline_3_0
    case h264Baseline_3_1
    case h264Main_3_1
    case h264High_4_1
}

#if os(macOS) || os(iOS)
    import CoreFoundation
    import VideoToolbox
    extension H264ProfileLevel {
        var raw: CFString {
            get {
                switch self {
                case .h264Baseline_3_0:
                    return kVTProfileLevel_H264_Baseline_3_0
                case .h264Baseline_3_1:
                    return kVTProfileLevel_H264_Baseline_3_1
                case .h264Main_3_1:
                    return kVTProfileLevel_H264_Main_3_1
                case .h264High_4_1:
                    return kVTProfileLevel_H264_High_4_1
                }
            }
        }
    }
#endif
