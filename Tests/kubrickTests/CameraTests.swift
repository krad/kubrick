import XCTest
@testable import kubrick

class CameraTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    #if os(macOS)
    func test_that_we_can_set_a_framerate() {
        useRealDeviceIO()
        
        let discovery   = AVDeviceDiscoverer()
        let src         = discovery.sources.filter { $0.type == .video }.first
        XCTAssertNotNil(src)
        
        XCTAssert(src!.deviceFormats.count > 0)
        
        for format in src!.deviceFormats {
            XCTAssert(format.frameRates.count > 0)
        }
    
        let camera = Camera(src!)
        XCTAssertNotNil(camera)
        XCTAssertEqual(24.0, camera.frameRate)

        let session = CaptureSession()
        session.addInput(camera)
        
        session.base.beginConfiguration()
        camera.frameRate = 30.0
        session.base.commitConfiguration()

        // iOS complains about this.
//        XCTAssertEqual(30, session.base.outputs.first?.connections.first?.videoMinFrameDuration.timescale)
//        XCTAssertEqual(30, session.base.outputs.first?.connections.first?.videoMaxFrameDuration.timescale)
    }
    #endif
    
}
