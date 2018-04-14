#if os(macOS) || os(iOS)
    import AVFoundation
#endif

public protocol Session {
    associatedtype Base: BaseSession
    func startRunning()
    func stopRunning()
    
    func addInput(_ input: MediaDevice, withOutputConnections: Bool)
    func removeInput(_ input: MediaDevice)
    func makeConnections(_ device: MediaDevice) throws
    
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
    func makeConnection(input: MediaDeviceInput, output: MediaDeviceOutput, for mediaType: MediaType) throws
}

public enum CaptureSessionError: Error {
    case couldNotMakeConnection(device: MediaDevice)
    case missingInput(device: MediaDevice)
    case missingOutput(device: MediaDevice)
    case missingMediaType(device: MediaDevice)
    case inputMissingPorts(mediaType: MediaType)
}

public class CaptureSession: Session {
    open let base = Base()
    
    public private(set) var inputs: [MediaDeviceInput] = []
    public private(set) var outputs: [MediaDeviceOutput] = []

    public init() { }
    
    
    /// Starts the CaptureSession
    public func startRunning() {
        self.base.startRunning()
    }
    
    /// Stops the CaptureSession
    public func stopRunning() {
        self.base.stopRunning()
    }
    
    /// Signal that we need to configure the CaptureSession
    public func beginConfiguration() {
        self.base.beginConfiguration()
    }
    
    /// Signal that we have completed configuring the CaptureSession
    public func commitConfiguration() {
        self.base.commitConfiguration()
    }
    
    
    /// Add Input & Output for a MediaDevice to the CaptureSession
    ///
    /// - Parameters:
    ///   - input: MediaDevice we should create i/o for
    ///   - withOutputConnections: Bool that signals whether the created output object should make a connection in the CaptureSesssion.  This is useful on macOS where multiple inputs can be created (defaults: true)
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
    
    /// Removes Input & Output for a MediaDevice from the CaptureSession
    ///
    /// - Parameter input: MediaDevice that should have it's i/o removed from the CaptureSession
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
    
    
    /// Make a connection between and Input and and Output in the CaptureSession
    /// Currently this is only useful on macOS when we need to add multiple inputs to a session
    ///
    /// - Parameter input: MediaDevice with input & output objects that should be bridged
    /// - Throws: Error describing any problem that could come up while building the session
    public func makeConnections(_ device: MediaDevice) throws {
        guard let input     = device.input       else { throw CaptureSessionError.missingInput(device: device) }
        guard let output    = device.output      else { throw CaptureSessionError.missingOutput(device: device) }
        guard let mediaType = device.source.type else { throw CaptureSessionError.missingMediaType(device: device) }
        
        try self.base.makeConnection(input: input, output: output, for: mediaType)
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
    
    public func makeConnection(input: MediaDeviceInput, output: MediaDeviceOutput, for mediaType: MediaType) throws {
        if let i = input as? AVCaptureInput, let o = output as? AVCaptureOutput {
            let ports = i.ports.filter { MediaType.from($0.mediaType) == mediaType }
            if ports.count > 0 {
                let connection = AVCaptureConnection(inputPorts: ports, output: o)
                if self.canAdd(connection) {
                    self.add(connection)
                }
            } else {
                throw CaptureSessionError.inputMissingPorts(mediaType: mediaType)
            }            
        }
    }
}
#endif
