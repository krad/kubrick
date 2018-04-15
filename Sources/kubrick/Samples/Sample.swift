public protocol Sample {
    var bytes: [UInt8] { get }
    var pts: Rational { get }
    var dts: Rational { get }
    var duration: Rational { get }
    var numberOfSamples: Int { get }
    var format: MediaFormat? { get }
    var type: SampleType { get }
    
    var isSync: Bool { get }
    var dependsOnOthers: Bool { get }
    var earlierPTSAllowed: Bool { get }
    
    func metadata() -> [String: Any]?
    func setMetaData(key: String, value: Any)
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
        
        public var numberOfSamples: Int {
            return CMSampleBufferGetNumSamples(self)
        }
        
        public var format: MediaFormat? {
            return CMSampleBufferGetFormatDescription(self)
        }
        
        public var type: SampleType {
            if let format = self.format { return format.mediaType }
            return .unknown
        }
        
        internal var sampleAttachments: [CFString: Any]? {
            if let buffAttach = CMSampleBufferGetSampleAttachmentsArray(self, false) as? [Any] {
                if let attachments = buffAttach.first as? [CFString: Any] {
                    return attachments
                }
            }
            return nil
        }
        
        internal func attachmentValue(for key: CFString) -> Bool {
            if let dict = self.sampleAttachments {
                if let value = dict[key] as? Bool {
                    return value
                }
            }
            return false
        }
        
        public var isSync: Bool {
            return !self.notSync
        }
        
        internal var notSync: Bool {
            return self.attachmentValue(for: kCMSampleAttachmentKey_NotSync)
        }
        
        public var dependsOnOthers: Bool {
            return self.attachmentValue(for: kCMSampleAttachmentKey_DependsOnOthers)
        }
        
        public var earlierPTSAllowed: Bool {
            return self.attachmentValue(for: kCMSampleAttachmentKey_EarlierDisplayTimesAllowed)
        }
        
        public func metadata() -> [String : Any]? {
            if let cfattachments = CMCopyDictionaryOfAttachments(nil,
                                                              self,
                                                              kCMAttachmentMode_ShouldPropagate) {
                if let attachments = cfattachments as? [String : Any] {
                    if let metadata = attachments["com.krad.kubrick.metadata"] as? [String: Any] {
                        return metadata
                    }
                }
            }
            return nil
        }
        
        public func setMetaData(key: String, value: Any) {
            var dict: [String: Any] = [:]
            if let metaDict = self.metadata() { dict = metaDict }
            dict[key] = value
            CMSetAttachment(self,
                            "com.krad.kubrick.metadata" as CFString,
                            dict as CFDictionary,
                            CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        }

    }
    
#endif
