#if os(macOS) || os(iOS)
    import AVFoundation
#endif

public protocol Session {
    associatedtype Base: BaseSession
    func startRunning()
    func stopRunning()
    func addInput(_ input: MediaDevice)
}

public protocol BaseSession {
    func startRunning()
    func stopRunning()
    func xaddInput(_ input: MediaDeviceInput)
    func xaddOutput(_ output: MediaDeviceOutput)
}

public class CaptureSession: Session {
    public let base = Base()
    
    public init() {}
 
    public func startRunning() {
        self.base.startRunning()
    }
    
    public func stopRunning() {
        self.base.stopRunning()
    }
    
    public func addInput(_ input: MediaDevice) {
        input.createInput { self.base.xaddInput($0) }
        input.createOutput { self.base.xaddOutput($0) }
    }
}

#if os(macOS) || os(iOS)
    extension CaptureSession {
        public typealias Base = AVCaptureSession
    }
    
    extension AVCaptureSession: BaseSession {
        public func xaddOutput(_ output: MediaDeviceOutput) {
            if let o = output as? AVCaptureVideoDataOutput {
                if self.canAddOutput(o) {
                    self.addOutput(o)
                }
            }
            
            if let o = output as? AVCaptureAudioDataOutput {
                if self.canAddOutput(o) {
                    self.addOutput(o)
                }
            }
        }
        
        public func xaddInput(_ input: MediaDeviceInput) {
            if let i = input as? AVCaptureDeviceInput {
                if self.canAddInput(i) {
                    self.addInput(i)
                }
            }
        }
    }
#endif
