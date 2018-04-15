import XCTest
@testable import kubrick
#if os(macOS)
    import AVFoundation
#endif

class DisplayStreamTests: XCTestCase {

    #if os(macOS)
    func test_that_we_can_stream_display_video() {
        useRealDeviceIO()
        
        let subject = AVDeviceDiscoverer()
        var display = subject.displays.last
        XCTAssertEqual(display?.source.localizedName, "Color LCD")
        
        let reader = VideoReader()
        XCTAssertNil(display?.reader)
        XCTAssertNoThrow(try display!.set(reader: reader))
        XCTAssertNotNil(display?.reader)
        
        let mockSink = MockSink<SampleTransport>()
        XCTAssertEqual(0, mockSink.samples.count)
        reader.sinks.append(mockSink)

        let session = CaptureSession()
        XCTAssertEqual(0, session.inputs.count)
        session.addInput(display!)
        XCTAssertEqual(1, session.inputs.count)
        XCTAssertEqual(1, session.outputs.count)
        
        session.startRunning()
        let e = self.expectation(description: "sink wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { e.fulfill() }
        self.wait(for: [e], timeout: 2)
        
        XCTAssertNotEqual(0, mockSink.samples.count)
    }
    #endif
    
}
