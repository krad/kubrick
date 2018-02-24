import Dispatch

public class AACEncoderSink: Sink {
    
    public var q: DispatchQueue
    public var mediaType: MediaType = .audio
    public var sink: Sink?
    public var encoder: AudioEncoder?
    
    init() {
        self.q = DispatchQueue(label: "aac.encoder.sink.q")
    }

}


#if os(macOS) || os(iOS)

    extension AACEncoderSink {
        public func push(sample: Sample) {
            if self.encoder == nil { self.encoder = AACEncoder() }
            self.encoder?.encode(sample, onComplete: { (bytes, duration) in
                print("Encoded \(duration) aac")
            })
        }
    }
    
#endif
