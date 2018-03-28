public protocol MediaDeviceInput {
    var hashValue: Int { get }
    static func makeInput(device: Source) throws -> MediaDeviceInput
}

internal typealias MediaDeviceInputCreateCallback  = (MediaDeviceInput) -> Void
internal typealias MakeMediaDeviceInput = (Source, MediaDeviceInputCreateCallback) throws -> MediaDeviceInput

public enum MediaDeviceInputError: Error {
    case couldNotCreateInput
}

func ==(lhs: MediaDeviceInput, rhs: MediaDeviceInput) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

#if os(macOS) || os(iOS)
    import AVFoundation

    var makeInput: MakeMediaDeviceInput = { src, onCreate in
        let input = try AVCaptureInput.makeInput(device: src)
        onCreate(input)
        return input
    }
    
    extension MediaDevice {
        public mutating func createInput(onCreate: MediaDeviceInputClosure) {
            do { self.input = try kubrick.makeInput(self.source, onCreate) }
            catch { }
        }
    }
    
    extension AVCaptureInput: MediaDeviceInput {
        static public func makeInput(device: Source) throws -> MediaDeviceInput {
            if let dev = device as? AVCaptureDevice {
                return try AVCaptureDeviceInput(device: dev)
            }
            
            #if os(macOS)
            if let dev = device as? DisplaySource {
                return AVCaptureScreenInput(displayID: dev.displayID)
            }
            #endif
            
            throw MediaDeviceInputError.couldNotCreateInput
        }
    }
    
#endif
