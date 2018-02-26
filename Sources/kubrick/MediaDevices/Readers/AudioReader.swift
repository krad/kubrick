import Dispatch

public class AudioReader: NSObject, MediaDeviceReader {

    public var q                     = DispatchQueue(label: "audio.reader.q")
    public var mediaType             = MediaType.audio
    public var sinks: [Sink<Sample>] = []
    
    public override init() { super.init() }
    
}

#if os(macOS) || os(iOS)
    import AVFoundation
    extension AudioReader: AVCaptureAudioDataOutputSampleBufferDelegate {
        public func captureOutput(_ output: AVCaptureOutput,
                                  didOutput sampleBuffer: CMSampleBuffer,
                                  from connection: AVCaptureConnection)
        {
            self.q.async { self.push(input: sampleBuffer) }
        }
    }
#endif
