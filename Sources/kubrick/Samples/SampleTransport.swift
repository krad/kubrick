public struct SampleTransport {
    public let sourceIdentifier: MediaSourceIdentifier
    public let sample: Sample
    public var metadata: [String: Any]?
}

#if os(macOS) || os(iOS)
import CoreMedia

extension SampleTransport {
    
    init(sourceIdentifier: MediaSourceIdentifier, sampleBuffer: CMSampleBuffer) {
        self.sourceIdentifier = sourceIdentifier
        self.sample           = sampleBuffer
        if let cfattachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                             sampleBuffer,
                                                             kCMAttachmentMode_ShouldPropagate) {
            if let attachments = cfattachments as? [String: Any] {
                self.metadata = attachments
            }
        }
    }
    
}
#endif
