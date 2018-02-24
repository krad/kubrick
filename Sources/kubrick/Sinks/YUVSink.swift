import Dispatch

public class YUVSink: NSObject, Sink {
    
    public var q: DispatchQueue
    public let mediaType: MediaType = .video
    public var sink: Sink?
    public var samples: [Sample] = []
    
    override init() {
        self.q = DispatchQueue(label: "yuv.reader.q")
        super.init()
    }
    
}

#if os(macOS) || os(iOS)
    import AVFoundation
    extension YUVSink: AVCaptureVideoDataOutputSampleBufferDelegate {
        public func captureOutput(_ output: AVCaptureOutput,
                                  didOutput sampleBuffer: CMSampleBuffer,
                                  from connection: AVCaptureConnection)
        {
            print(#function)
        }
    }
    
#endif
