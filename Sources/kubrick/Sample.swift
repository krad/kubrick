public enum SampleType {
    case audio
    case video
}

public protocol Sample {
    var type: SampleType { get }
}
