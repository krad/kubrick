import XCTest
@testable import kubrick

class SessionTests: XCTestCase {

    func test_that_we_can_setup_a_capture_session() {
        kubrick.makeInput  = makeInputMock
        kubrick.makeOutput = makeOutputMock

        let session = CaptureSession()
        let camera  = Camera(MockCameraSource(""))
        XCTAssertNil(camera.input)
        XCTAssertNil(camera.output)
        
        session.addInput(camera)
        
        XCTAssertNotNil(camera.input)
        XCTAssertNotNil(camera.output)
        
    }
    
}
