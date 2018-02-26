public typealias VideoEncodedCallback = (Sample) -> Void

public enum VideoEncoderError: Error {
    case failedSetup
}

public protocol VideoEncoder {
    func encode(_ sample: Sample, onComplete: @escaping VideoEncodedCallback)
}
