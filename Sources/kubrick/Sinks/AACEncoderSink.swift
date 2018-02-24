import Dispatch

public class AACEncoderSink: Sink {
    
    public var q: DispatchQueue
    public var mediaType: MediaType = .audio
    public var sink: Sink?
    
    public var encoder: AudioEncoder?
    
    init() {
        self.q = DispatchQueue(label: "aac.encoder.sink.q")
    }
    
    public func push(sample: Sample) {
//        print(sample)
    }

}


#if os(macOS) || os(iOS)
#endif
