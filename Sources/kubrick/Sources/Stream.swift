import Dispatch
import grip

#if os(iOS) && !TARGET_IPHONE_SIMULATOR
    import Metal
#endif

public protocol StreamProtocol {
    var session: CaptureSession { get }
    var devices: [MediaDevice] { get }
    var readers: [MediaDeviceReader] { get }
    func set(endpoint: Writeable)
}

public enum StreamError: Error {
    case noDevicesSelected
    case gpuUnavailable
}

public class Stream: StreamProtocol {
    
    public var session: CaptureSession
    public var devices: [MediaDevice]
    public var readers: [MediaDeviceReader]
    
    internal var videoEncoderSink: H264EncoderSink?
    internal var audioEncoderSink: AACEncoderSink?
    internal var muxSink: MuxerSink
    internal var endPointSink: EndpointSink?
    
    #if os(iOS) && !TARGET_IPHONE_SIMULATOR
    public var prettyPortrait: PrettyPortrait
    #endif
    
    public init(devices: [MediaDevice]) throws {
        guard devices.count > 0 else { throw StreamError.noDevicesSelected }
        
        // Create a capture session and save the devices the user set
        self.session = CaptureSession()
        self.devices = devices
        
        // Create a muxer sink and wire it into our encoders
        self.muxSink = MuxerSink()
        
        #if os(iOS) && !TARGET_IPHONE_SIMULATOR
            if let gpu = MTLCreateSystemDefaultDevice() {
                self.prettyPortrait = try PrettyPortrait(device: gpu)
            } else {
                throw StreamError.gpuUnavailable
            }
        #endif
        
        // Create readers for each of the devices
        self.readers = self.devices.flatMap {
            if $0.source.type == .audio { return AudioReader() }
            if $0.source.type == .video { return VideoReader() }
            return nil
        }
        
        // Add the devices as inputs to the session
        self.devices.forEach { (device) in self.session.addInput(device) }

        // Attach each of the readers to their appropriate devices
        for var device in self.devices {
            let rdrs = self.readers.filter { $0.mediaType == device.source.type }
            try rdrs.forEach { try device.set(reader: $0) }
        }
        
        let videoReaders = self.readers.filter { $0.mediaType == .video }
        let audioReaders = self.readers.filter { $0.mediaType == .audio }
        
        // Attach the video encoders to the video reader
        if videoReaders.count > 0 {
            var encoderSettings = H264Settings()
            
            let cameras = self.devices.filter { $0.source.type == .video }
            if let camera = cameras.first as? Camera {
                encoderSettings.frameRate = Float(camera.frameRate)
            }
            
            #if os(iOS)
                for var reader in videoReaders { reader.sinks.append(self.prettyPortrait) }
                self.videoEncoderSink = try H264EncoderSink(settings: encoderSettings)
                self.prettyPortrait.nextSinks.append(self.videoEncoderSink!)
                muxSink.streamType.insert(.video)
            #else
                self.videoEncoderSink = try H264EncoderSink(settings: encoderSettings)
                for var reader in videoReaders {
                    reader.sinks.append(self.videoEncoderSink!)
                    muxSink.streamType.insert(.video)
                }
            #endif
        }
        
        // Attach the audio encoder to the audio reader
        if audioReaders.count > 0 {
            self.audioEncoderSink = AACEncoderSink()
            for var reader in audioReaders {
                reader.sinks.append(self.audioEncoderSink!)
                muxSink.streamType.insert(.audio)
            }
        }
        
        self.videoEncoderSink?.nextSinks.append(self.muxSink)
        self.audioEncoderSink?.nextSinks.append(self.muxSink)
        
        return
    }
    
    public func set(endpoint: Writeable) {
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // If we have a video format, build the config packets and send them
            if let videoFormat = self.muxSink.videoFormat {
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
            self.muxSink.nextSinks.append(sink)
        }
    }

}
