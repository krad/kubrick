import grip

public class TCPSessionSink: Sink<Sample>, NextSinkProtocol {
    
    public var nextSinks: [Sink<[UInt8]>] = []
    
    internal var videoFormat: VideoFormatDescription?
    internal var audioFormat: AudioFormatDescription?
    
    public override func push(input: Sample) {
        
    }
    
}
