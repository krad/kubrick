public protocol MediaDeviceInput {
    static func makeInput(device: Source) throws -> MediaDeviceInput
}

internal typealias MediaDeviceInputCreateCallback  = (MediaDeviceInput) -> Void
internal typealias MakeMediaDeviceInput  = (Source, MediaDeviceInputCreateCallback) throws -> MediaDeviceInput

#if os(macOS) || os(iOS)
    import AVFoundation

    var makeInput: MakeMediaDeviceInput = { src, onCreate in
        let input = try AVCaptureDeviceInput.makeInput(device: src)
        onCreate(input)
        return input
    }
    
    extension MediaDevice {
        public mutating func createInput(onCreate: (MediaDeviceInput) -> Void) {
            do { self.input = try kubrick.makeInput(self.source, onCreate) }
            catch { }
        }
    }
    
    extension AVCaptureDeviceInput : MediaDeviceInput {
        static public func makeInput(device: Source) throws -> MediaDeviceInput {
            return try AVCaptureDeviceInput(device: device as! AVCaptureDevice)
        }
    }
#endif