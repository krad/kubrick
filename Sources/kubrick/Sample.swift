public enum SampleType {
    case audio
    case video
}

public protocol Sample {
    var bytes: [UInt8] { get }
    var pts: Rational { get }
    var dts: Rational { get }
    var duration: Rational { get }
}

#if os(macOS) || os(iOS)
    import CoreMedia
    
    extension CMSampleBuffer: Sample {
        public var bytes: [UInt8] {
            if let b = getBytes(from: self) { return b }
            return []
        }
        
        public var pts: Rational {
            let ts = CMSampleBufferGetPresentationTimeStamp(self)
            return Rational(numerator: ts.value, denominator: ts.timescale)
        }
        
        public var dts: Rational {
            let ts = CMSampleBufferGetDecodeTimeStamp(self)
            return Rational(numerator: ts.value, denominator: ts.timescale)
        }
        
        public var duration: Rational {
            let ts = CMSampleBufferGetDuration(self)
            return Rational(numerator: ts.value, denominator: ts.timescale)
        }
    }
    
#endif
