import Dispatch
import grip

public class H264EncoderSink: Sink<Sample>, NextSinkProtocol {
    
    public typealias OutputType = Sample
    public var nextSinks: [Sink<Sample>] = []

    public var encoder: VideoEncoder?
    
    init(settings: H264Settings) throws {
        self.encoder = try H264Encoder(settings)
    }
    
    #if os(macOS) || os(iOS)
    public override func push(input: Sample) {
        self.encoder?.encode(input, onComplete: { (sample) in
            for sink in self.nextSinks {
                sink.push(input: sample)
            }
        })
    }
    #endif
    
}
