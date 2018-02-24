import Dispatch

public enum SinkError: Error {
    case incompatibleMediaType
}

public protocol Sink {
    var q: DispatchQueue { get }
    var mediaType: MediaType { get }
    var sink: Sink? { get }
    func push(sample: Sample)
}

