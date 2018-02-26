import grip

public class MuxerSink: Sink<Sample>, NextSinkProtocol {
    
    /// Sinks downstream from us types that adopt BinaryEncodable
    public var nextSinks: [Sink<BinaryEncodable>] = []
    
    internal var videoFormat: VideoFormatDescription?
    internal var audioFormat: AudioFormatDescription?
    internal var streamType: StreamType = StreamType()
    
    public override init() { }
    
    /// Sink push - Receives a Sample we need to pull config info from and forward on to a TCPSink
    ///
    /// - Parameter input: Sample that supports Audio / Video
    public override func push(input: Sample) {
        guard checkForValidFormat(for: input) else { return }
        switch input.type {
        case .audio:
            let packet = AudioSamplePacket(duration: input.duration.numerator,
                                           timescale: UInt32(input.duration.denominator),
                                           data: input.bytes)
            self.send(packet)
        case .video:
            var packet = VideoSamplePacket(duration: input.duration.numerator,
                                           timescale: UInt32(input.duration.denominator),
                                           data: input.bytes)
            
            packet.isSync                    = input.isSync
            packet.dependsOnOther            = input.dependsOnOthers
            packet.earlierDisplayTimesAllows = input.earlierPTSAllowed
            self.send(packet)
        default: return
        }
    }
    
    /// checkForValidFormat - Will read the format details of the sample and store/send them if they change.
    ///
    /// - Parameter input: Sample
    /// - Returns: Returns true if the sample contained a format we support
    private func checkForValidFormat(for input: Sample) -> Bool {
        if let format = input.format?.details {
            switch input.type {
            case .audio:
                if let fmt = format as? AudioFormatDescription {
                    if fmt != audioFormat { self.audioFormat = fmt }
                    self.streamType.insert(.audio)
                    return true
                }
            case .video:
                if let fmt = format as? VideoFormatDescription {
                    if fmt != videoFormat { self.videoFormat = fmt }
                    self.streamType.insert(.video)
                    return true
                }
            default: return false
            }
        }
        return false
    }
    
    private func send(_ packet: BinaryEncodable) {
        for sink in self.nextSinks {
            sink.push(input: packet)
        }
    }
    
}
