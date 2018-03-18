public protocol MediaDeviceOutput {
    var hashValue: Int { get }
    func set(_ reader: MediaDeviceReader)
}

func ==(lhs: MediaDeviceOutput, rhs: MediaDeviceOutput) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

internal typealias MediaDeviceOutputCreateCallback = (MediaDeviceOutput) -> Void
internal typealias MakeMediaDeviceOutput = (Source, MediaDeviceOutputCreateCallback) -> MediaDeviceOutput?

#if os(macOS) || os(iOS)
    import AVFoundation
    
    var makeOutput: MakeMediaDeviceOutput = { src, onCreate in
        switch src.type {
        case .video?:
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]

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
        public func set(_ reader: MediaDeviceReader) {
            if let delegate = reader as? AVCaptureVideoDataOutputSampleBufferDelegate {
                self.setSampleBufferDelegate(delegate, queue: reader.q)
            }
        }
    }
    
    extension AVCaptureAudioDataOutput: MediaDeviceOutput {
        public func set(_ reader: MediaDeviceReader) {
            if let delegate = reader as? AVCaptureAudioDataOutputSampleBufferDelegate {
                self.setSampleBufferDelegate(delegate, queue: reader.q)
            }
        }
    }
#endif
