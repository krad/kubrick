
#if os(macOS) || os(iOS)
    import AVFoundation
#endif

public protocol MediaDevice {
    var source: Source { get }
    var input: MediaDeviceInput? { get set }
    var output: MediaDeviceOutput? { get set }
    mutating func createInput(onCreate: (MediaDeviceInput) -> Void)
    mutating func createOutput(onCreate: (MediaDeviceOutput) -> Void)
}

public protocol MediaDeviceInput {
    static func makeInput(device: Source) throws -> MediaDeviceInput
}

public protocol MediaDeviceOutput { }

internal typealias MediaDeviceInputCreateCallback  = (MediaDeviceInput) -> Void
internal typealias MediaDeviceOutputCreateCallback = (MediaDeviceOutput) -> Void
internal typealias MakeMediaDeviceInput  = (Source, MediaDeviceInputCreateCallback) throws -> MediaDeviceInput
internal typealias MakeMediaDeviceOutput = (Source, MediaDeviceOutputCreateCallback) -> MediaDeviceOutput?

#if os(macOS) || os(iOS)

    var makeInput: MakeMediaDeviceInput = { src, onCreate in
        let input = try AVCaptureDeviceInput.makeInput(device: src)
        onCreate(input)
        return input
    }
    
    var makeOutput: MakeMediaDeviceOutput = { src, onCreate in
        switch src.type {
        case .video?:
            let output = AVCaptureVideoDataOutput()
            onCreate(output)
            return output
        case .audio?:
            let output = AVCaptureAudioDataOutput()
            onCreate(output)
            return output
        case .none:
            return nil
        }
    }
    
    extension MediaDevice {
        public mutating func createInput(onCreate: (MediaDeviceInput) -> Void) {
            do { self.input = try kubrick.makeInput(self.source, onCreate) }
            catch { }
        }
        
        public mutating func createOutput(onCreate: (MediaDeviceOutput) -> Void) {
            self.output = kubrick.makeOutput(self.source, onCreate)
        }
    }
    
    extension AVCaptureDeviceInput : MediaDeviceInput {
        static public func makeInput(device: Source) throws -> MediaDeviceInput {
            return try AVCaptureDeviceInput(device: device as! AVCaptureDevice)
        }
    }
    
    extension AVCaptureVideoDataOutput: MediaDeviceOutput { }
    extension AVCaptureAudioDataOutput: MediaDeviceOutput { }
#endif
