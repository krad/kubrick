import Dispatch

public class VideoReader: NSObject, MediaDeviceReader {

    public var ident: String
    public var q                     = DispatchQueue(label: "video.reader.q")
    public var clock: Clock?
    public var mediaType             = MediaType.video
    public var sinks: [Sink<Sample>] = []
    
    public init(_ ident: String? = nil) {
        if let i = ident { self.ident = i }
        else { self.ident = UUID().uuidString }
    }
    
}

#if os(macOS) || os(iOS)
    import AVFoundation
    extension VideoReader: AVCaptureVideoDataOutputSampleBufferDelegate {
        public func captureOutput(_ output: AVCaptureOutput,
                                  didOutput sampleBuffer: CMSampleBuffer,
                                  from connection: AVCaptureConnection)
        {
            self.q.async { self.push(input: sampleBuffer) }
        }        
    }
#endif
