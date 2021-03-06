import Foundation
@testable import kubrick

class MockSource: MediaSource {
    
    func sources() -> [Source] {
        return [MockCameraSource(""), MockMicrophoneSource()]
    }
    
    func sources(_ scope: MediaSourceScope) -> [Source] {
        return self.sources()
    }
    
    #if os(macOS)
    func displays() -> [DisplaySource] {
        return []
    }
    #endif
}

class MockDeviceInput: MediaDeviceInput {
    static func makeInput(device: Source) throws -> MediaDeviceInput {
        return MockDeviceInput()
    }
    
    var hashValue: Int = Int(arc4random())
}

class MockDeviceOutput: MediaDeviceOutput {
    func set(_ reader: MediaDeviceReader) { }
    var hashValue: Int = Int(arc4random())
}

var makeInputMock: MakeMediaDeviceInput = { src, onCreate in
    let input = MockDeviceInput()
    onCreate(input)
    return input
}

var makeOutputMock: MakeMediaDeviceOutput = { src, onCreate in
    let output = MockDeviceOutput()
    onCreate(output)
    return output
}

class MockSink<T>: Sink<T> {
    var samples: [T] = []
    override func push(input: T) {
        self.samples.append(input)
    }
}

#if os(macOS) || os(iOS)
    import AVFoundation
    
    class MockCameraSource: AVCaptureDevice {
        override var uniqueID: String { return self.fakeModelID }
        override var isConnected: Bool { return true }
        override var position: AVCaptureDevice.Position { return .unspecified }
        override var modelID: String { return self.fakeModelID }
        override var localizedName: String { return "Fake Front Camera" }
        
        var fakeModelID: String = ""
        
        override var activeVideoMinFrameDuration: CMTime {
            get { return CMTimeMake(1, 30) }
            set { }
        }
        override var activeVideoMaxFrameDuration: CMTime {
            get { return CMTimeMake(1, 30) }
            set { }
        }
        
        override func hasMediaType(_ mediaType: AVMediaType) -> Bool {
            if mediaType == .video { return true }
            return false
        }
        
        init(_ forceInit: String) {
            self.fakeModelID = forceInit
        }
        
        override func lockForConfiguration() throws { }
        override func unlockForConfiguration() { }
    }
#else
    extension MockCameraSource: Source {
        override var uniqueID: String { return UUID().uuidString }
        override var isConnected: Bool { return true }
        override var position: AVCaptureDevice.Position { return .unspecified }
        override var modelID: String { return "Fake Cam v2" }
        override var localizedName: String { return "Fake Front Camera" }
        var manufacturer: String { return "The Test Harness Company" }
        
        override func hasMediaType(_ mediaType: AVMediaType) -> Bool {
            if mediaType == .video { return true }
            return false
        }
        init(_ forceInit: String) { }
    }
#endif

class MockMicrophoneSource: Source {
    var uniqueID       : String         = UUID().uuidString
    var isConnected    : Bool           = true
    var devicePosition : DevicePosition = .unspecified
    var modelID        : String         = "Fake Mic v2"
    var localizedName  : String         = "Fake Microphone"
    var manufacturer   : String         = "The Test Harness Company"
    var type           : MediaType?     = .audio
    var deviceFormats  : [DeviceFormat] = []
}
