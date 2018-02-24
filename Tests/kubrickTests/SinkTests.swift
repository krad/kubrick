import XCTest
@testable import kubrick
import AVFoundation

class SinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        //useMockDeviceIO()
        self.continueAfterFailure = false
    }

    func test_that_we_can_add_a_sink_to_a_device_without_a_session() {
        let sink    = YUVSink()
        var camera  = Camera(MockCameraSource(""))
        
        XCTAssertNil(camera.sink)
        XCTAssertNoThrow(try camera.set(sink: sink))
        XCTAssertNotNil(camera.sink)
        
        var mic    = Microphone(MockMicrophoneSource())
        XCTAssertThrowsError(try mic.set(sink: sink))
    }
    
    func test_that_we_can_add_a_sink_to_a_device_that_belongs_to_a_session() {
        let session = CaptureSession()
        var camera  = Camera(MockCameraSource(""))
        XCTAssertNil(camera.input)
        XCTAssertNil(camera.output)
        
        session.addInput(camera)
        
        let sink    = YUVSink()
        XCTAssertNoThrow(try camera.set(sink: sink))
    }

    #if os(macOS)
    func test_that_we_can_capture_data() {
        useRealDeviceIO()
        
        let discover = AVDeviceDiscoverer()
        let videoSrc = discover.sources.filter { $0.type == .video }.first
        XCTAssertNotNil(videoSrc)
        
        var camera = Camera(videoSrc!)
        XCTAssertNil(camera.input)
        XCTAssertNil(camera.output)
        
        let session = CaptureSession()
        session.addInput(camera)
        XCTAssertNotNil(camera.input)
        XCTAssertNotNil(camera.output)
        
        if let _ = camera.input as? MockDeviceInput { XCTFail("We have a fake input") }
        if let _ = camera.output as? MockDeviceOutput { XCTFail("We have a fake output") }
        
        let sink = YUVSink()
        XCTAssertEqual(sink.samples.count, 0)
        
        XCTAssertNoThrow(try camera.set(sink: sink))
        
        session.startRunning()
        let e = self.expectation(description: "Capturing data")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            e.fulfill()
        }
        self.wait(for: [e], timeout: 5)
        
        XCTAssertTrue(sink.samples.count > 0)
    }
    #endif

    
}
