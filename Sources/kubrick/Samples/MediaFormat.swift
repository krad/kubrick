public protocol MediaFormat {
    var mediaType: String { get }
    var mediaSubType: String { get }
    var details: MediaSpecificFormatDescription? { get }
}

public protocol MediaSpecificFormatDescription { }

public struct AudioFormatDescription: MediaSpecificFormatDescription {
    var sampleRate: Float64
    var formatID: UInt32
    var formatFlags: UInt32
    var bytesPerPacket: UInt32
    var framesPerPacket: UInt32
    var bytesPerFrame: UInt32
    var channelsPerFrame: UInt32
    var bitsPerChannel: UInt32
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

#if os(macOS) || os(iOS)
    import CoreMedia
    
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
    
    extension CMFormatDescription: MediaFormat {
        
        public var mediaType: String {
            return fourCCToString(CMFormatDescriptionGetMediaType(self))
        }
        
        public var mediaSubType: String {
            return fourCCToString(CMFormatDescriptionGetMediaSubType(self))
        }
        
        public var details: MediaSpecificFormatDescription? {
            if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(self) {
                return AudioFormatDescription(asbd.pointee)
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
    
#endif
