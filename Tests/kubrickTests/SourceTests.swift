import XCTest
@testable import kubrick

class SourceTests: XCTestCase {
    func test_that_we_can_add_a_video_input() {
        kubrick.makeInput  = makeInputMock
        kubrick.makeOutput = makeOutputMock

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
}
