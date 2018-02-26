import XCTest
@testable import kubrick

class StreamTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }
    
    func test_that_we_can_create_a_new_session_without_exploding() {
        let src       = MockSource()
        let discovery = AVDeviceDiscoverer(src)
        XCTAssert(discovery.devices.count > 0)
        XCTAssertNoThrow(try Stream(devices: discovery.devices))
        
        let stream = try? Stream(devices: discovery.devices)
        XCTAssertNotNil(stream)
        XCTAssertEqual(stream?.devices.count, discovery.devices.count)
        XCTAssertEqual(stream?.readers.count, discovery.devices.count)
        
        XCTAssertNotNil(stream?.videoEncoderSink)
        XCTAssertNotNil(stream?.audioEncoderSink)
        
        XCTAssertEqual(1, stream?.videoEncoderSink?.nextSinks.count)
        XCTAssertEqual(1, stream?.audioEncoderSink?.nextSinks.count)
        XCTAssertNil(stream?.endPointSink)
    }
    
}
