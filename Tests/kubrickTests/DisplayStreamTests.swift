import XCTest
@testable import kubrick

class DisplayStreamTests: XCTestCase {

    #if os(macOS)
    func test_that_we_can_stream_display_video() {
        let subject = AVDeviceDiscoverer()
        let display = subject.devices.last
        XCTAssertEqual(display?.source.localizedName, "Color LCD")
        
        let session = CaptureSession()
        XCTAssertEqual(0, session.inputs.count)
        session.addInput(display!)
        XCTAssertEqual(1, session.inputs.count)

    }
    #endif
    
}
