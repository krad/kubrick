#if os(macOS) || os(iOS)
    import AVFoundation
#endif

public protocol MediaDevice {
    var source: Source { get }
    var input: MediaDeviceInput? { get }
    var output: MediaDeviceOutput? { get set }
    func createInput(onCreate: (MediaDeviceInput) -> Void)
    func createOutput(onCreate: (MediaDeviceOutput) -> Void)
}

public class Camera: MediaDevice {
    public var source: Source
    public var input: MediaDeviceInput?
    public var output: MediaDeviceOutput?
    
    init(_ source: Source) {
        self.source = source
    }
}

public class Microphone: MediaDevice {
    public var source: Source
    public var input: MediaDeviceInput?
    public var output: MediaDeviceOutput?
    
    init(_ source: Source) {
        self.source = source
    }
}

public protocol MediaDeviceInput { }
public protocol MediaDeviceOutput { }

#if os(macOS) || os(iOS)
    
    extension MediaDevice {
        public func createInput(onCreate: (MediaDeviceInput) -> Void) {
            do {
                if let src = self.source as? AVCaptureDevice {
                    let input = try AVCaptureDeviceInput(device: src)
                    onCreate(input)
                }
            } catch { }
        }
        
        public func createOutput(onCreate: (MediaDeviceOutput) -> Void) {
            switch self.source.type {
            case .video?:
                let output = AVCaptureVideoDataOutput()
                onCreate(output)
            case .audio?:
                let output = AVCaptureAudioDataOutput()
                onCreate(output)
            case .none:
                return
            }
        }
    }
    
    extension AVCaptureDeviceInput : MediaDeviceInput { }
    extension AVCaptureVideoDataOutput: MediaDeviceOutput { }
    extension AVCaptureAudioDataOutput: MediaDeviceOutput { }
#endif
