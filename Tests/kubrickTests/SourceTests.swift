import XCTest
@testable import kubrick

class SourceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        useMockDeviceIO()
    }
        
    func test_that_we_can_add_a_video_input() {
        let session      = CaptureSession()
        let cameraSource = MockCameraSource("")
        let camera       = Camera(cameraSource)
        
        XCTAssertNil(camera.input)
        XCTAssertNil(camera.output)
        XCTAssertEqual(camera.source.type, .video)
        
        session.addInput(camera)

        XCTAssertNotNil(camera.input)
        XCTAssertNotNil(camera.output)
    }
    
    func test_that_we_can_add_an_audio_input() {
        let session   = CaptureSession()
        let micSource = MockMicrophoneSource()
        let mic       = Microphone(micSource)
        
        XCTAssertNil(mic.input)
        XCTAssertNil(mic.output)
        XCTAssertEqual(mic.source.type, .audio)
        
        session.addInput(mic)
        
        XCTAssertNotNil(mic.input)
        XCTAssertNotNil(mic.output)
    }
}
