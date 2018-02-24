import Dispatch

public class AudioSink: NSObject, Sink {
    
    public var q: DispatchQueue
    public let mediaType: MediaType = .audio
    public var sink: Sink?
    internal var samples = ThreadSafeArray<Sample>()
    
    override public init() {
        self.q = DispatchQueue(label: "audio.reader.q")
        super.init()
    }
    
    public func push(sample: Sample) {
        if let nextSink = self.sink {
            nextSink.push(sample: sample)
            self.samples.removeFirst(n: 1)
        }
    }
    
    internal func push() {
        if let sample = self.samples.first {
            self.push(sample: sample)
        }
    }
    
}

#if os(macOS) || os(iOS)
    import AVFoundation
    extension AudioSink: AVCaptureAudioDataOutputSampleBufferDelegate {
        public func captureOutput(_ output: AVCaptureOutput,
                                  didOutput sampleBuffer: CMSampleBuffer,
                                  from connection: AVCaptureConnection)
        {
            self.q.async {
                self.samples.append(sampleBuffer)
                self.push()
            }
        }
    }
#endif
