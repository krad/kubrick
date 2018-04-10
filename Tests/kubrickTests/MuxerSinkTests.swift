import XCTest
@testable import kubrick

class MuxerSinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    #if os(macOS)
    func test_that_we_can_capture_data() {
        useRealDeviceIO()
        
        let discover = AVDeviceDiscoverer()
        let videoSrc = discover.sources.filter { $0.type == .video }.first
        let audioSrc = discover.sources.filter { $0.type == .audio }.first
        
        var camera = Camera(videoSrc!)
        var mic    = Microphone(audioSrc!)
        
        let session = CaptureSession()
        session.addInput(camera)
        session.addInput(mic)
        
        let video = VideoReader()
        XCTAssertNoThrow(try camera.set(reader: video))
        
        let audio = AudioReader()
        XCTAssertNoThrow(try mic.set(reader: audio))

        let h264Settings = H264Settings(profile: .h264Main_3_1, frameRate: 25, width: 640, height: 480)
        let h264Sink = try! H264EncoderSink(settings: h264Settings)
        h264Sink.running = true
        video.sinks.append(h264Sink)
        
        let aacSink = AACEncoderSink()
        aacSink.running = true
        audio.sinks.append(aacSink)
        
        let muxSink = MuxerSink()
        h264Sink.nextSinks.append(muxSink)
        aacSink.nextSinks.append(muxSink)
        
        XCTAssertNil(muxSink.videoFormat)
        XCTAssertNil(muxSink.audioFormat)
        XCTAssertEqual(muxSink.streamType, [])
        
        session.startRunning()
        
        let e = self.expectation(description: "Capturing data")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { e.fulfill() }
        self.wait(for: [e], timeout: 5)
        
        XCTAssertNotNil(muxSink.videoFormat)
        XCTAssertNotNil(muxSink.audioFormat)
        XCTAssertEqual(muxSink.streamType, [.video, .audio])

    }
    #endif

    
}
