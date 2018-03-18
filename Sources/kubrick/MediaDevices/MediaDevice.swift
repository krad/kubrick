public typealias MediaDeviceInputClosure    = (MediaDeviceInput) -> Void
public typealias MediaDeviceOutputClosure   = (MediaDeviceOutput) -> Void

public protocol MediaDevice {
    var source: Source { get }
    var input: MediaDeviceInput? { get set }
    var output: MediaDeviceOutput? { get set }
    var reader: MediaDeviceReader? { get set }

    mutating func createInput(onCreate: MediaDeviceInputClosure)
    mutating func createOutput(onCreate: MediaDeviceOutputClosure)
    mutating func set(reader: MediaDeviceReader) throws
}

public func ==(lhs: MediaDevice, rhs: MediaDevice) -> Bool {
    return lhs.source.uniqueID == rhs.source.uniqueID
}

extension MediaDevice {
    public mutating func set(reader: MediaDeviceReader) throws {
        if reader.mediaType == self.source.type {
            self.reader     = reader
            if let output = self.output { output.set(reader) }
        } else {
            throw SinkError.incompatibleMediaType
        }
    }
}
