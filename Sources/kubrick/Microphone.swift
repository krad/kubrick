public class Microphone: MediaDevice {
    public var source: Source
    public var input: MediaDeviceInput?
    public var output: MediaDeviceOutput?
    
    init(_ source: Source) {
        self.source = source
    }
}
