public protocol MediaFormat {
    var mediaType: String { get }
    var mediaSubType: String { get }
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
    
    extension CMFormatDescription: MediaFormat {
        public var mediaType: String {
            return fourCCToString(CMFormatDescriptionGetMediaType(self))
        }
        
        public var mediaSubType: String {
            return fourCCToString(CMFormatDescriptionGetMediaSubType(self))
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
