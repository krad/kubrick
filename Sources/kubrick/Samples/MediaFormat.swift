import grip

public protocol MediaFormat {
    var mediaType: SampleType { get }
    var mediaSubType: SampleSubType { get }
    var details: MediaSpecificFormatDescription? { get }
}

public protocol MediaSpecificFormatDescription { }

public struct AudioFormatDescription: MediaSpecificFormatDescription {
    var sampleRate:         Float64
    var formatID:           UInt32
    var formatFlags:        UInt32
    var bytesPerPacket:     UInt32
    var framesPerPacket:    UInt32
    var bytesPerFrame:      UInt32
    var channelsPerFrame:   UInt32
    var bitsPerChannel:     UInt32
}

extension AudioFormatDescription: Equatable {
    // TODO: There's gotta be a better way that this
    public static func ==(lhs: AudioFormatDescription, rhs: AudioFormatDescription) -> Bool {
        if lhs.sampleRate == rhs.sampleRate {
            if lhs.formatID == rhs.formatID {
                if lhs.formatFlags == rhs.formatFlags {
                    if lhs.bytesPerPacket == rhs.bytesPerPacket {
                        if lhs.framesPerPacket == rhs.framesPerPacket {
                            if lhs.bytesPerFrame == rhs.bytesPerFrame {
                                if lhs.channelsPerFrame == rhs.channelsPerFrame {
                                    if lhs.bitsPerChannel == rhs.bitsPerChannel {
                                        return true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return false
    }
}

public struct VideoFormatDescription: MediaSpecificFormatDescription {
    public var dimensions: VideoDimensions
    public var params: [[UInt8]]
}

public protocol FrameRateRange {
    var maxDuration: Rational { get }
    var maxRate: Float64 { get }
    var minDuration: Rational { get }
    var minRate: Float64 { get }
}


extension VideoFormatDescription: Equatable {
    public static func ==(lhs: VideoFormatDescription, rhs: VideoFormatDescription) -> Bool {
        if lhs.dimensions == rhs.dimensions {
            return true
        }
        return false
    }
}

public enum SampleType: String {
    case audio    = "soun"
    case video    = "vide"
    case muxed    = "muxx"
    case text     = "text"
    case captions = "clcp"
    case subtitle = "sbtl"
    case timecode = "tmcd"
    case metadata = "meta"
    case unknown  = "wat?"
}

public enum SampleSubType: String {
    case h264    = "avc1"
    case aac     = "aac "
    case lpcm    = "lpcm"
    case twoVUY  = "2vuy"
    case unknown = "wat?"
}

#if os(macOS) || os(iOS)
    import CoreMedia
    import AVFoundation
    
    //extension CMFormatDescription: MediaSpecificFormatDescription { }
    
    extension AVFrameRateRange: FrameRateRange {
        public var maxDuration: Rational {
            return Rational(numerator: self.maxFrameDuration.value,
                            denominator: self.maxFrameDuration.timescale)
        }
        
        public var maxRate: Float64 {
            return self.maxFrameRate
        }
        
        public var minDuration: Rational {
            return Rational(numerator: self.minFrameDuration.value,
                            denominator: self.minFrameDuration.timescale)
        }
        
        public var minRate: Float64 {
            return self.minFrameRate
        }
        
    }
    
    extension AudioFormatDescription {
        init(_ streamDesc: AudioStreamBasicDescription) {
            self.sampleRate       = streamDesc.mSampleRate
            self.formatID         = streamDesc.mFormatID
            self.formatFlags      = streamDesc.mFormatFlags
            self.bytesPerPacket   = streamDesc.mBytesPerPacket
            self.framesPerPacket  = streamDesc.mFramesPerPacket
            self.bytesPerFrame    = streamDesc.mBytesPerFrame
            self.channelsPerFrame = streamDesc.mChannelsPerFrame
            self.bitsPerChannel   = streamDesc.mBitsPerChannel
        }
        
        var asbd: AudioStreamBasicDescription {
            return AudioStreamBasicDescription(mSampleRate: self.sampleRate,
                                               mFormatID: self.formatID,
                                               mFormatFlags: self.formatFlags,
                                               mBytesPerPacket: self.bytesPerPacket,
                                               mFramesPerPacket: self.framesPerPacket,
                                               mBytesPerFrame: self.bytesPerFrame,
                                               mChannelsPerFrame: self.channelsPerFrame,
                                               mBitsPerChannel: self.bitsPerChannel,
                                               mReserved: 0)
        }
    }
    
    extension VideoFormatDescription {
        init(_ format: CMVideoFormatDescription) {
            let dim         = CMVideoFormatDescriptionGetDimensions(format)
            self.dimensions = VideoDimensions(width: UInt32(dim.width), height: UInt32(dim.height))
            self.params     = getVideoFormatDescriptionData(format)
        }
    }
    
    extension CMFormatDescription: MediaFormat {
        
        public var mediaType: SampleType {
            if let st = SampleType(rawValue: fourCCToString(CMFormatDescriptionGetMediaType(self))) {
                return st
            } else {
                return .unknown
            }
        }
        
        public var mediaSubType: SampleSubType {
            if let st = SampleSubType(rawValue: fourCCToString(CMFormatDescriptionGetMediaSubType(self))) {
                return st
            } else {
                return .unknown
            }
        }
        
        public var details: MediaSpecificFormatDescription? {
            switch self.mediaType {
            case .video:
                return VideoFormatDescription(self)

            case .audio:
                if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(self) {
                    return AudioFormatDescription(asbd.pointee)
                }
            default:
                return nil
            }
            return nil
        }

    }
    
    func fourCCToString(_ value: FourCharCode) -> String {
        let utf16 = [
            UInt16((value >> 24) & 0xFF),
            UInt16((value >> 16) & 0xFF),
            UInt16((value >> 8) & 0xFF),
            UInt16((value & 0xFF)) ]
        return String(utf16CodeUnits: utf16, count: 4)
    }
    
    public func getVideoFormatDescriptionData(_ format: CMFormatDescription) -> [[UInt8]] {
        var results: [[UInt8]] = []
        
        var numberOfParamSets: size_t = 0
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, nil, nil, &numberOfParamSets, nil)
        
        for idx in 0..<numberOfParamSets {
            var params: UnsafePointer<UInt8>? = nil
            var paramsLength: size_t         = 0
            var headerLength: Int32          = 4
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, idx, &params, &paramsLength, nil, &headerLength)
            
            let bufferPointer   = UnsafeBufferPointer(start: params, count: paramsLength)
            let paramsUnwrapped = Array(bufferPointer)
            
            let result: [UInt8] =  paramsUnwrapped
            results.append(result)
        }
        
        return results
    }

    
#endif
