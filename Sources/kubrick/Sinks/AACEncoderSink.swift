import Dispatch
import grip


/// This is an AACEncoder sink.
/// You pass in LPCM samples and it dispatches AudioSamplePacket's with AAC compressed audio
public class AACEncoderSink: Sink<SampleTransport>, NextSinkProtocol {
    public var encoder: AudioEncoder?
    public var running: Bool = false
    public var nextSinks: [Sink<Sample>] = []
    
    public override init() { }
    
    #if os(macOS) || os(iOS)
    public override func push(input: SampleTransport) {
        guard self.running else { return }
        if self.encoder == nil { self.encoder = AACEncoder() }
        self.encoder?.encode(input.sample, onComplete: { sample in
            for sink in self.nextSinks {
                sink.push(input: sample)
            }
        })
    }    
    #endif

}
