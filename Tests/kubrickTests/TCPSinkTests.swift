import XCTest
@testable import kubrick

class TCPSinkTests: XCTestCase {
    
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
        
        let tcpSessionSink = MuxerSink()
        h264Sink.nextSinks.append(tcpSessionSink)
        aacSink.nextSinks.append(tcpSessionSink)
        
        XCTAssertNil(tcpSessionSink.videoFormat)
        XCTAssertNil(tcpSessionSink.audioFormat)
        
        session.startRunning()
        
        let e = self.expectation(description: "Capturing data")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { e.fulfill() }
        self.wait(for: [e], timeout: 5)
        
        XCTAssertNotNil(tcpSessionSink.videoFormat)
        XCTAssertNotNil(tcpSessionSink.audioFormat)

        
    }
    #endif

    
}
