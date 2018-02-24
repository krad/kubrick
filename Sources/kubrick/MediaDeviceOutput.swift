public protocol MediaDeviceOutput {
    func set(sink: Sink)
}

internal typealias MediaDeviceOutputCreateCallback = (MediaDeviceOutput) -> Void
internal typealias MakeMediaDeviceOutput = (Source, MediaDeviceOutputCreateCallback) -> MediaDeviceOutput?

#if os(macOS) || os(iOS)
    import AVFoundation
    
    var makeOutput: MakeMediaDeviceOutput = { src, onCreate in
        switch src.type {
        case .video?:
            let output = AVCaptureVideoDataOutput()
            onCreate(output)
            return output
        case .audio?:
            let output = AVCaptureAudioDataOutput()
            #if os(macOS)
                output.audioSettings = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsNonInterleaved: false,
                ]
            #endif

            onCreate(output)
            return output
        case .none:
            return nil
        }
    }
    
    extension MediaDevice {
        public mutating func createOutput(onCreate: (MediaDeviceOutput) -> Void) {
            self.output = kubrick.makeOutput(self.source, onCreate)
        }
    }
    
    extension AVCaptureVideoDataOutput: MediaDeviceOutput {
        public func set(sink: Sink) {
            if let delegate = sink as? AVCaptureVideoDataOutputSampleBufferDelegate {
                self.setSampleBufferDelegate(delegate, queue: sink.q)
            }
        }
    }
    
    extension AVCaptureAudioDataOutput: MediaDeviceOutput {
        public func set(sink: Sink) {
            if let delegate = sink as? AVCaptureAudioDataOutputSampleBufferDelegate {
                self.setSampleBufferDelegate(delegate, queue: sink.q)
            }
        }
    }
#endif
