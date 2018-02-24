public protocol MediaDevice {
    var source: Source { get }
    var input: MediaDeviceInput? { get set }
    var output: MediaDeviceOutput? { get set }
    var sink: Sink? { get set }
    
    mutating func createInput(onCreate: (MediaDeviceInput) -> Void)
    mutating func createOutput(onCreate: (MediaDeviceOutput) -> Void)
    mutating func set(sink: Sink) throws
}

extension MediaDevice {
    public mutating func set(sink: Sink) throws {
        if sink.mediaType == self.source.type {
            self.sink     = sink
            if let output = self.output { output.set(sink: sink) }
        } else {
            throw SinkError.incompatibleMediaType
        }
    }
}
