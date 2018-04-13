#if os(macOS) || os(iOS)
    import AVFoundation
#endif

public protocol Session {
    associatedtype Base: BaseSession
    func startRunning()
    func stopRunning()
    func addInput(_ input: MediaDevice, withOutputConnections: Bool)
    func removeInput(_ input: MediaDevice)
    
    func beginConfiguration()
    func commitConfiguration()
}

public protocol BaseSession {
    func startRunning()
    func stopRunning()
    func beginConfiguration()
    func commitConfiguration()
    func xaddInput(_ input: MediaDeviceInput) -> Bool
    func xaddOutput(_ output: MediaDeviceOutput, withOutputConnections: Bool) -> Bool
    func xremoveInput(_ input: MediaDeviceInput)
    func xremoveOutput(_ output: MediaDeviceOutput)
}

public class CaptureSession: Session {
    open let base = Base()
    
    public private(set) var inputs: [MediaDeviceInput] = []
    public private(set) var outputs: [MediaDeviceOutput] = []

    public init() { }
    
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
    
    public func addInput(_ input: MediaDevice, withOutputConnections: Bool = true) {
        var inputBuilder = input
        
        inputBuilder.createInput {
            if self.base.xaddInput($0) {
                self.inputs.append($0)
            }
        }
        
        inputBuilder.createOutput {
            if self.base.xaddOutput($0, withOutputConnections: withOutputConnections) {
                self.outputs.append($0)
                if var reader = input.reader {
                    reader.clock = self.base.masterClock
                    $0.set(reader)
                }
            }
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

        public func xaddOutput(_ output: MediaDeviceOutput, withOutputConnections: Bool) -> Bool {
            if let o = output as? AVCaptureVideoDataOutput {
                if self.canAddOutput(o) {
                    if withOutputConnections {
                        self.addOutput(o)
                    } else {
                        self.addOutputWithNoConnections(o)
                    }
                    return true
                }
            }
            
            if let o = output as? AVCaptureAudioDataOutput {
                if self.canAddOutput(o) {
                    self.addOutput(o)
                    return true
                }
            }
            
            return false
        }
        
        public func xaddInput(_ input: MediaDeviceInput) -> Bool {
            if let i = input as? AVCaptureDeviceInput {
                if self.canAddInput(i) {
                    self.addInput(i)
                    return true
                }
            }
            
            #if os(macOS)
            if let i = input as? AVCaptureScreenInput {
                if self.canAddInput(i) {
                    self.addInput(i)
                    return true
                }
            }
            #endif
            
            return false
        }
        
        public func xremoveInput(_ input: MediaDeviceInput) {
            if let i = input as? AVCaptureDeviceInput { self.removeInput(i) }
        }
        
        public func xremoveOutput(_ output: MediaDeviceOutput) {
            if let o = output as? AVCaptureVideoDataOutput { self.removeOutput(o) }
            if let o = output as? AVCaptureAudioDataOutput { self.removeOutput(o) }
        }
    }
#endif
