import grip

public protocol StreamProtocol {
    var session: CaptureSession { get }
    var devices: [MediaDevice] { get }
    var readers: [MediaDeviceReader] { get }
    func set(endpoint: Writeable)
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
    internal var endPointSink: EndpointSink?
    
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
        
        // Attach the video encoders to the video reader
        if let videoEncoder = self.videoEncoderSink {
            for var reader in videoReaders {
                print("Appending video encoder to video reader", reader)
                reader.sinks.append(videoEncoder)
                muxSink.streamType.insert(.video)
            }
        }
        
        // Attach the audio encoder to the audio reader
        if let audioEncoder = self.audioEncoderSink {
            for var reader in audioReaders {
                print("Appending audio encoder to audio reader", reader)
                reader.sinks.append(audioEncoder)
                muxSink.streamType.insert(.audio)
            }
        }
        
        // Add the devices as inputs to the session
        self.devices.forEach { (device) in self.session.addInput(device) }
        
        // That's it.  Don't wire any of our sinks into the pipeline until we're ready.
        return
    }
    
    public func set(endpoint: Writeable) {
        print(#function)
        let sink          = EndpointSink(endpoint)
        self.endPointSink = sink
        
        /// Start actually encoding video for sending
        self.videoEncoderSink?.running = true
        self.audioEncoderSink?.running = true
        
        // Get the stream type from the mux sink
        // We appending the mux sinks to the av encoders earlier so by now they should have samples
        print("Sending stream type:", muxSink.streamType)
        let streamTypePacket = StreamTypePacket(streamType: muxSink.streamType)
        self.endPointSink?.push(input: streamTypePacket)
        
        // If we have a video format, build the config packets and send them
        if let videoFormat = muxSink.videoFormat {
            do {
                let paramsPacket     = try VideoParamSetPacket(params: videoFormat.params)
                let dimensionsPacket = VideoDimensionPacket(width: videoFormat.dimensions.width,
                                                            height: videoFormat.dimensions.height)

                print("Sending video params", paramsPacket)
                self.endPointSink?.push(input: paramsPacket)
                print("Sending dimensions", dimensionsPacket)
                self.endPointSink?.push(input: dimensionsPacket)
            } catch let error {
                print("Problem configuring video portion of stream:", error)
            }
        }
        
        // Append the endpoint sink to the mux sink
        // Audio / Video data should start streaming over the network from here
        muxSink.nextSinks.append(sink)
    }

}
