import XCTest
@testable import kubrick

class VideoSinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }
    
    #if os(macOS) || os(iOS)
    func test_that_we_can_capture_and_encode_h264_video() {
        useRealDeviceIO()
        
        let discover = AVDeviceDiscoverer()
        let videoSrc = discover.sources.filter { $0.type == .video }.first
        XCTAssertNotNil(videoSrc)
        
        var camera      = Camera(videoSrc!)
        let reader      = VideoReader()
        let settings    = H264Settings(profile: .h264Baseline_3_0,
                                       frameRate: 25.0,
                                       width: 480, height: 640)
        
        var encoderSink: H264EncoderSink?
        XCTAssertNoThrow(encoderSink = try H264EncoderSink(settings: settings))
        XCTAssertNotNil(encoderSink)
        reader.sinks.append(encoderSink!)

        let out = MockSink<Sample>()
        encoderSink?.nextSinks.append(out)
        
        let session = CaptureSession()
        session.addInput(camera)
        XCTAssertNoThrow(try camera.set(reader: reader))
        
        session.startRunning()
    
        let e = self.expectation(description: "Capture and compress some video data")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { e.fulfill() }
        self.wait(for: [e], timeout: 3)
        
        XCTAssertTrue(out.samples.count > 0)
        
        
    }
    #endif
    
}
