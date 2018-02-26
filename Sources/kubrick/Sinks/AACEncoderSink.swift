import Dispatch
import grip

public class AACEncoderSink: Sink<Sample> {
    public var encoder: AudioEncoder?
    
    public var encodedSamples = ThreadSafeArray<AudioSamplePacket>()
    
    #if os(macOS) || os(iOS)
    public override func push(input: Sample) {
        if self.encoder == nil { self.encoder = AACEncoder() }
        self.encoder?.encode(input, onComplete: { (bytes, duration) in
            if let bytes = bytes, let duration = duration {
                let packet = AudioSamplePacket(duration: duration.numerator,
                                               timescale: UInt32(duration.denominator),
                                               data: bytes)
                self.encodedSamples.append(packet)
            }
        })
    }    
    #endif

}
