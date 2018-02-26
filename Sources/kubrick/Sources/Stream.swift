import grip

public protocol StreamProtocol {
    var session: CaptureSession { get }
    var devices: [MediaDevice] { get }
    var readers: [MediaDeviceReader] { get }
}

public enum StreamError: Error {
    case noDevicesSelected
}

public class Stream: StreamProtocol {
    
    public var session: CaptureSession
    public var devices: [MediaDevice]
    public var readers: [MediaDeviceReader]
    
    internal var videoEncoderSink: H264EncoderSink?
    internal var audioEncoderSink: AACEncoderSink?
    internal var muxSink: MuxerSink
    
    public init(devices: [MediaDevice]) throws {
        guard devices.count > 0 else { throw StreamError.noDevicesSelected }
        
        // Create a capture session and save the devices the user set
        self.session = CaptureSession()
        self.devices = devices
        
        // Create readers for each of the devices
        self.readers = self.devices.flatMap {
            if $0.source.type == .audio { return AudioReader() }
            if $0.source.type == .video { return VideoReader() }
            return nil
        }
        
        // Attach each of the readers to their appropriate devices
        for var device in self.devices {
            let rdrs = self.readers.filter { $0.mediaType == device.source.type }
            try rdrs.forEach { try device.set(reader: $0) }
        }
        
        // Setup appropriate encoders based on what reader's we've created
        let videoReaders = self.readers.filter { $0.mediaType == .video }
        let audioReaders = self.readers.filter { $0.mediaType == .audio }
        
        if videoReaders.count > 0 { self.videoEncoderSink = try H264EncoderSink() }
        if audioReaders.count > 0 { self.audioEncoderSink = AACEncoderSink() }
        
        // Create a muxer sink and wire it into our encoders
        self.muxSink = MuxerSink()
        self.videoEncoderSink?.nextSinks.append(self.muxSink)
        self.audioEncoderSink?.nextSinks.append(self.muxSink)
        
        // That's it.  Don't wire any of our sinks into the pipeline until we're ready.
        return
    }
    
}
