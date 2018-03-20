#if os(macOS) || os(iOS)
    import AVFoundation
#endif

public protocol Session {
    associatedtype Base: BaseSession
    func startRunning()
    func stopRunning()
    func addInput(_ input: MediaDevice)
    func removeInput(_ input: MediaDevice)
    
    func beginConfiguration()
    func commitConfiguration()
}

public protocol BaseSession {
    func startRunning()
    func stopRunning()
    func xaddInput(_ input: MediaDeviceInput)
    func xaddOutput(_ output: MediaDeviceOutput)
    func xremoveInput(_ input: MediaDeviceInput)
    func xremoveOutput(_ output: MediaDeviceOutput)
}

public class CaptureSession: Session {
    public let base = Base()
    
    public private(set) var inputs: [MediaDeviceInput] = []
    public private(set) var outputs: [MediaDeviceOutput] = []

    public init() {}
    
    public func startRunning() {
        self.base.startRunning()
    }
    
    public func stopRunning() {
        self.base.stopRunning()
    }
    
    public func beginConfiguration() {
        self.base.beginConfiguration()
    }
    
    public func commitConfiguration() {
        self.base.commitConfiguration()
    }
    
    public func addInput(_ input: MediaDevice) {
        var inputBuilder = input
        
        inputBuilder.createInput {
            self.base.xaddInput($0)
            self.inputs.append($0)
        }
        
        inputBuilder.createOutput {
            self.base.xaddOutput($0)
            self.outputs.append($0)
            
            if let reader = input.reader { $0.set(reader) }
        }
    }
    
    public func removeInput(_ input: MediaDevice) {
        if let input = input.input {
            self.base.xremoveInput(input)
            if let idx = self.inputs.index(where: { $0 == input }) {
                self.inputs.remove(at: idx)
            }
        }
        
        if let output = input.output {
            self.base.xremoveOutput(output)
            if let idx = self.outputs.index(where: { $0 == output }) {
                self.outputs.remove(at: idx)
            }
        }
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
        
        public func xremoveInput(_ input: MediaDeviceInput) {
            if let i = input as? AVCaptureDeviceInput {
                self.removeInput(i)
            }
        }
        
        public func xremoveOutput(_ output: MediaDeviceOutput) {
            if let o = output as? AVCaptureVideoDataOutput {
                self.removeOutput(o)
            }
            
            if let o = output as? AVCaptureAudioDataOutput {
                self.removeOutput(o)
            }
        }
    }
#endif
