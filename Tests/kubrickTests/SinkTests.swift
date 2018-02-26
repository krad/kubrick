    import XCTest
@testable import kubrick
import AVFoundation

class SinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        useMockDeviceIO()
        self.continueAfterFailure = false
    }

    func test_that_we_can_add_a_sink_to_a_device_without_a_session() {
        let video   = VideoReader()
        var camera  = Camera(MockCameraSource(""))
        
        XCTAssertNil(camera.reader)
        XCTAssertNoThrow(try camera.set(reader: video))
        XCTAssertNotNil(camera.reader)
        
        var mic    = Microphone(MockMicrophoneSource())
        XCTAssertThrowsError(try mic.set(reader: video))
        
        let audio = AudioReader()
        XCTAssertNil(mic.reader)
        XCTAssertNoThrow(try mic.set(reader: audio))
        XCTAssertNotNil(mic.reader)
    }
    
    func test_that_we_can_add_a_sink_to_a_device_that_belongs_to_a_session() {
        let session = CaptureSession()
        var camera  = Camera(MockCameraSource(""))
        XCTAssertNil(camera.input)
        XCTAssertNil(camera.output)
        
        session.addInput(camera)
        
        let video = VideoReader()
        XCTAssertNoThrow(try camera.set(reader: video))
    }
    
}
