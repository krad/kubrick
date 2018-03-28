import Dispatch

public protocol MediaDeviceReader {
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
