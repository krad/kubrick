import Dispatch

public class VideoSink: NSObject, Sink {
    
    public var q: DispatchQueue
    public let mediaType: MediaType = .video
    public var sink: Sink?
    public var samples: [Sample] = []
    
    override public init() {
        self.q = DispatchQueue(label: "video.reader.q")
        super.init()
    }
    
}

#if os(macOS) || os(iOS)
    import AVFoundation
    extension VideoSink: AVCaptureVideoDataOutputSampleBufferDelegate {
        public func captureOutput(_ output: AVCaptureOutput,
                                  didOutput sampleBuffer: CMSampleBuffer,
                                  from connection: AVCaptureConnection)
        {
            self.q.async { self.samples.append(sampleBuffer) }
        }
    }
    
#endif
