import XCTest
@testable import kubrick

class SessionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        useMockDeviceIO()
    }

    func test_that_we_can_setup_a_capture_session() {
        let session = CaptureSession()
        let camera  = Camera(MockCameraSource(""))
        XCTAssertNil(camera.input)
        XCTAssertNil(camera.output)
        
        session.addInput(camera)
        
        XCTAssertNotNil(camera.input)
        XCTAssertNotNil(camera.output)
    }
    
}
