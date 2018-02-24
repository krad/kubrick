public typealias AudioEncodedCallback = ([UInt8]?, Rational?) -> Void

public protocol AudioEncoder {
    var configured: Bool { get }
    func setup(using sample: Sample)
    func encode(_ sample: Sample, onComplete: AudioEncodedCallback)
}
