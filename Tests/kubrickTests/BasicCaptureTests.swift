import XCTest
@testable import kubrick

class BasicCaptureTests: XCTestCase {
    
    #if os(macOS)
    func test_that_we_can_capture_data() {
        useRealDeviceIO()
        
        let discover = AVDeviceDiscoverer()
        let videoSrc = discover.sources.filter { $0.type == .video }.first
        let audioSrc = discover.sources.filter { $0.type == .audio }.first
        XCTAssertNotNil(videoSrc)
        XCTAssertNotNil(audioSrc)
        
        var camera = Camera(videoSrc!)
        XCTAssertNil(camera.input)
        XCTAssertNil(camera.output)
        
        var mic = Microphone(audioSrc!)
        XCTAssertNil(mic.input)
        XCTAssertNil(mic.output)
        
        let session = CaptureSession()
        session.addInput(camera)
        XCTAssertNotNil(camera.input)
        XCTAssertNotNil(camera.output)
        
        session.addInput(mic)
        XCTAssertNotNil(mic.input)
        XCTAssertNotNil(mic.output)
        
        if let _ = camera.input as? MockDeviceInput { XCTFail("We have a fake camera input") }
        if let _ = camera.output as? MockDeviceOutput { XCTFail("We have a fake camera output") }
        
        if let _ = mic.input as? MockDeviceInput { XCTFail("We have a fake mic input") }
        if let _ = mic.output as? MockDeviceOutput { XCTFail("We have a fake mic output") }
        
        let video = VideoReader()
        let vSink = MockSink<SampleTransport>()
        video.sinks.append(vSink)
        XCTAssertEqual(vSink.samples.count, 0)
        XCTAssertNoThrow(try camera.set(reader: video))
        
        let audio   = AudioReader()
        let aSink   = MockSink<SampleTransport>()
        audio.sinks.append(aSink)
        XCTAssertEqual(aSink.samples.count, 0)
        XCTAssertNoThrow(try mic.set(reader: audio))
        
        session.startRunning()
        
        let e = self.expectation(description: "Capturing data")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { e.fulfill() }
        self.wait(for: [e], timeout: 5)
        
        XCTAssertTrue(vSink.samples.count > 0)
        XCTAssertTrue(aSink.samples.count > 0)
        
        let vSample = vSink.samples.first?.sample
        let aSample = aSink.samples.first?.sample
        XCTAssertEqual(vSample?.type, .video)
        XCTAssertEqual(aSample?.type, .audio)
        
        XCTAssertNotNil(vSample?.format)
        XCTAssertEqual(vSample?.format?.mediaSubType, .twoVUY)
        
        XCTAssertNotNil(aSample?.format)
        XCTAssertEqual(aSample?.format?.mediaSubType, .lpcm)
        
        XCTAssertNotNil(aSample?.format)
        XCTAssertNotNil(aSample?.format?.details)
    }
    #endif

    
}
