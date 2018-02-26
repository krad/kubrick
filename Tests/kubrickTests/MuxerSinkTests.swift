import XCTest
@testable import kubrick

class MuxerSinkTests: XCTestCase {
    
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

        let h264Sink = try! H264EncoderSink()
        video.sinks.append(h264Sink)
        
        let aacSink = AACEncoderSink()
        audio.sinks.append(aacSink)
        
        let muxSink = MuxerSink()
        h264Sink.nextSinks.append(muxSink)
        aacSink.nextSinks.append(muxSink)
        
        XCTAssertNil(muxSink.videoFormat)
        XCTAssertNil(muxSink.audioFormat)
        XCTAssertEqual(muxSink.streamType, [])
        
        session.startRunning()
        
        let e = self.expectation(description: "Capturing data")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { e.fulfill() }
        self.wait(for: [e], timeout: 5)
        
        XCTAssertNotNil(muxSink.videoFormat)
        XCTAssertNotNil(muxSink.audioFormat)
        XCTAssertEqual(muxSink.streamType, [.video, .audio])

    }
    #endif

    
}
