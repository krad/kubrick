public protocol VideoEncoderSettings {}

public struct H264Settings {
    var profile: H264ProfileLevel
    var frameRate: Float
    var width: Int
    var height: Int
    
    public init(profile: H264ProfileLevel = .h264Baseline_3_0,
                frameRate: Float = 25.0,
                width: Int = 480,
                height: Int = 640)
    {
        self.profile    = profile
        self.frameRate  = frameRate
        self.width      = width
        self.height     = height
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
