import XCTest
@testable import kubrick

class AudioSinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    #if os(macOS)
    func test_that_we_can_encode_pcm_samples_into_aac() {
        
        let discovery = AVDeviceDiscoverer()
        let audioSrc  = discovery.sources.filter { $0.type == .audio }.first
        XCTAssertNotNil(audioSrc)
        
        var mic       = Microphone(audioSrc!)
        let audioSink = AudioSink()
        let aacSink   = AACEncoderSink()
        
        audioSink.sink = aacSink
        
        let session = CaptureSession()
        session.addInput(mic)
        
        XCTAssertNoThrow(try mic.set(sink: audioSink))
        
        session.startRunning()
        let e = self.expectation(description: "Should encode some audio samples")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { e.fulfill() }
        self.wait(for: [e], timeout: 3)
        
        session.stopRunning()
        
    }
    #endif
    
}
