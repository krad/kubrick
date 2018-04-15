import Dispatch

public typealias MediaSourceIdentifier = String

public protocol MediaDeviceReader {
    var ident: MediaSourceIdentifier { get }
    var mediaType: MediaType { get }
    var clock: Clock? { get set }
    var q: DispatchQueue { get }
    var sinks: [Sink<Sample>] { get set }
}

extension MediaDeviceReader {
    public func push(input: Sample) {
        for next in self.sinks {
            next.push(input: input)
        }
    }
}
