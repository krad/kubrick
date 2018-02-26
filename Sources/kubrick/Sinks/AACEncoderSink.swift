import Dispatch
import grip

public class AACEncoderSink: Sink<Sample>, NextSinkProtocol {
    public var encoder: AudioEncoder?
    
    public var nextSinks: [Sink<AudioSamplePacket>] = []
    
    
    #if os(macOS) || os(iOS)
    public override func push(input: Sample) {
        if self.encoder == nil { self.encoder = AACEncoder() }
        self.encoder?.encode(input, onComplete: { (bytes, duration) in
            if let bytes = bytes, let duration = duration {
                let packet = AudioSamplePacket(duration: duration.numerator,
                                               timescale: UInt32(duration.denominator),
                                               data: bytes)
                for sink in self.nextSinks {
                    sink.push(input: packet)
                }
            }
        })
    }    
    #endif

}
