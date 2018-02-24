import Dispatch

public class AudioSink: NSObject, Sink {
    
    public var q: DispatchQueue
    public let mediaType: MediaType = .audio
    public var sink: Sink?
    public var samples: [Sample] = []
    
    override public init() {
        self.q = DispatchQueue(label: "audio.reader.q")
        super.init()
    }
    
}

#if os(macOS) || os(iOS)
    import AVFoundation
    extension AudioSink: AVCaptureAudioDataOutputSampleBufferDelegate {
        public func captureOutput(_ output: AVCaptureOutput,
                                  didOutput sampleBuffer: CMSampleBuffer,
                                  from connection: AVCaptureConnection)
        {
            self.q.async { self.samples.append(sampleBuffer) }
        }
    }
#endif
