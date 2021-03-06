import XCTest
@testable import kubrick
import AVFoundation

class VideoSinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }
    
    #if os(macOS) || (os(iOS) && (arch(arm) || arch(arm64)))
    func test_that_we_can_capture_and_encode_h264_video() {
        useRealDeviceIO()
        
        let discover = AVDeviceDiscoverer()
        let videoSrc = discover.sources.filter { $0.type == .video }.first
        XCTAssertNotNil(videoSrc)
        
        var camera      = Camera(videoSrc!)
        let reader      = VideoReader()
        let settings    = H264Settings()
        
        var encoderSink: H264EncoderSink?
        XCTAssertNoThrow(encoderSink = try H264EncoderSink(settings: settings))
        XCTAssertNotNil(encoderSink)
        encoderSink?.running = true
        reader.sinks.append(encoderSink!)

        let out = MockSink<Sample>()
        encoderSink?.nextSinks.append(out)
        
        let session = CaptureSession()
        session.addInput(camera)
        XCTAssertNoThrow(try camera.set(reader: reader))
        
        session.startRunning()
    
        let e = self.expectation(description: "Capture and compress some video data")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { e.fulfill() }
        self.wait(for: [e], timeout: 3)
        
        XCTAssertTrue(out.samples.count > 0)
        
        let vSample = out.samples.first
        XCTAssertEqual(vSample?.type, .video)

        let format = vSample?.format
        XCTAssertNotNil(format)
        XCTAssertEqual(format?.mediaType, .video)
        XCTAssertEqual(format?.mediaSubType, .h264)
        
        XCTAssertNotNil(format?.details)
        
    }
    #endif
    
}
