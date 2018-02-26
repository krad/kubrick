import grip

public class MuxerSink: Sink<Sample>, NextSinkProtocol {
    
    /// Sinks downstream from us take arrays of unsigned 8 bit integers
    public var nextSinks: [Sink<[UInt8]>] = []
    
    internal var videoFormat: VideoFormatDescription?
    internal var audioFormat: AudioFormatDescription?
    
    public override init() { }
    
    /// Sink push - Receives a Sample we need to pull config info from and forward on to a TCPSink
    ///
    /// - Parameter input: Sample that supports Audio / Video
    public override func push(input: Sample) {
        guard checkValueFormat(for: input) else { return }
        self.send(bytes: input.bytes)
    }
    
    /// checkValidFormat - Will read the format details of the sample and store/send them if they change.
    ///
    /// - Parameter input: Sample
    /// - Returns: Returns true if the sample contained a format we support
    private func checkValueFormat(for input: Sample) -> Bool {
        if let format = input.format?.details {
            switch input.type {
            case .audio:
                if let fmt = format as? AudioFormatDescription {
                    if fmt != audioFormat { self.audioFormat = fmt }
                    return true
                }
            case .video:
                if let fmt = format as? VideoFormatDescription {
                    if fmt != videoFormat { self.videoFormat = fmt }
                    return true
                }
            default: return false
            }
        }
        return false
    }
    
    private func send(bytes: [UInt8]) {
        for sink in self.nextSinks {
            sink.push(input: bytes)
        }
    }
    
}
