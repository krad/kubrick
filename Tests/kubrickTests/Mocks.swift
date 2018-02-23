import Foundation
@testable import kubrick

class MockSource: MediaSource {
    func sources() -> [Source] {
        return [MockCameraSource(), MockMicrophoneSource()]
    }
}

class MockSink: Sink {
    
}

class MockCameraSource: Source {
    var uniqueID: String        = UUID().uuidString
    var isConnected: Bool       = true
    var position: Position      = .front
    var modelID: String         = "Fake Cam v2"
    var localizedName: String   = "Fake Front Camera"
    var manufacturer: String    = "The Test Harness Company"
    var type: MediaType?        = .video
}

class MockMicrophoneSource: Source {
    var output: Sink?
    var uniqueID: String        = UUID().uuidString
    var isConnected: Bool       = true
    var position: Position      = .unspecified
    var modelID: String         = "Fake Mic v2"
    var localizedName: String   = "Fake Microphone"
    var manufacturer: String    = "The Test Harness Company"
    var type: MediaType?        = .audio
}
