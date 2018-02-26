public typealias AudioEncodedCallback = (Sample) -> Void

public enum AudioEncoderError: Error {
    case failedSetup
}

public protocol AudioEncoder {
    var configured: Bool { get }
    func setup(using sample: Sample) throws
    func encode(_ sample: Sample, onComplete: @escaping AudioEncodedCallback)
}
