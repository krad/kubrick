import Dispatch

public class AudioReader: NSObject, MediaDeviceReader {

    public var ident: MediaSourceIdentifier
    public var clock: Clock?
    public var mediaType                      = MediaType.audio
    public var q                              = DispatchQueue(label: "audio.reader.q")
    public var sinks: [Sink<SampleTransport>] = []
    
    public init(_ ident: String? = nil) {
        if let i = ident { self.ident = i }
        else { self.ident = UUID().uuidString }
    }
    
}

#if os(macOS) || os(iOS)
    import AVFoundation
    extension AudioReader: AVCaptureAudioDataOutputSampleBufferDelegate {
        public func captureOutput(_ output: AVCaptureOutput,
                                  didOutput sampleBuffer: CMSampleBuffer,
                                  from connection: AVCaptureConnection)
        {
            self.q.async {
                let sample = SampleTransport(sourceIdentifier: self.ident, sampleBuffer: sampleBuffer)
                self.push(input: sample)
            }
        }
    }
#endif
