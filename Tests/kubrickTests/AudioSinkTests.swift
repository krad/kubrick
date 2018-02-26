import XCTest
@testable import kubrick

class AudioSinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    #if os(macOS)
    func test_that_we_can_encode_pcm_samples_into_aac() {
        useRealDeviceIO()
        
        let discovery = AVDeviceDiscoverer()
        let audioSrc  = discovery.sources.filter { $0.type == .audio }.first
        XCTAssertNotNil(audioSrc)

        var mic         = Microphone(audioSrc!)
        let audioReader = AudioReader()
        let aacSink     = AACEncoderSink()

        audioReader.sinks.append(aacSink)

        let session = CaptureSession()
        session.addInput(mic)

        XCTAssertNoThrow(try mic.set(reader: audioReader))
        XCTAssertEqual(0, aacSink.encodedSamples.count)

        session.startRunning()
        let e = self.expectation(description: "Should encode some audio samples")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { e.fulfill() }
        self.wait(for: [e], timeout: 3)

        session.stopRunning()
        XCTAssertTrue(aacSink.encodedSamples.count > 0)
                
    }
    #endif
    
}
