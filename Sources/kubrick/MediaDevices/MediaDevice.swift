public protocol MediaDevice {
    var source: Source { get }
    var input: MediaDeviceInput? { get set }
    var output: MediaDeviceOutput? { get set }
    var reader: MediaDeviceReader? { get set }
    
    mutating func createInput(onCreate: (MediaDeviceInput) -> Void)
    mutating func createOutput(onCreate: (MediaDeviceOutput) -> Void)
    mutating func set(reader: MediaDeviceReader) throws
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
