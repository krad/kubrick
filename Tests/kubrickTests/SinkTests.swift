import XCTest
@testable import kubrick
import AVFoundation

class SinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        useMockDeviceIO()
        self.continueAfterFailure = false
    }

    func test_that_we_can_add_a_sink_to_a_device_without_a_session() {
        let video   = VideoSink()
        var camera  = Camera(MockCameraSource(""))
        
        XCTAssertNil(camera.sink)
        XCTAssertNoThrow(try camera.set(sink: video))
        XCTAssertNotNil(camera.sink)
        
        var mic    = Microphone(MockMicrophoneSource())
        XCTAssertThrowsError(try mic.set(sink: video))
        
        let audio = AudioSink()
        XCTAssertNil(mic.sink)
        XCTAssertNoThrow(try mic.set(sink: audio))
        XCTAssertNotNil(mic.sink)
    }
    
    func test_that_we_can_add_a_sink_to_a_device_that_belongs_to_a_session() {
        let session = CaptureSession()
        var camera  = Camera(MockCameraSource(""))
        XCTAssertNil(camera.input)
        XCTAssertNil(camera.output)
        
        session.addInput(camera)
        
        let video = VideoSink()
        XCTAssertNoThrow(try camera.set(sink: video))
    }

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
        
        let video = VideoSink()
        XCTAssertEqual(video.samples.count, 0)
        XCTAssertNoThrow(try camera.set(sink: video))
        
        let audio = AudioSink()
        XCTAssertEqual(audio.samples.count, 0)
        XCTAssertNoThrow(try mic.set(sink: audio))
        
        session.startRunning()
        let e = self.expectation(description: "Capturing data")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { e.fulfill() }
        self.wait(for: [e], timeout: 5)
        
        XCTAssertTrue(video.samples.count > 0)
        XCTAssertTrue(audio.samples.count > 0)
        
        let vSample = video.samples.first
        let aSample = audio.samples.first
        XCTAssertEqual(vSample?.type, .video)
        XCTAssertEqual(aSample?.type, .audio)
        
        XCTAssertNotNil(vSample?.format)
        XCTAssertEqual(vSample?.format?.mediaSubType, "2vuy")
        
        XCTAssertNotNil(aSample?.format)
        XCTAssertEqual(aSample?.format?.mediaSubType, "lpcm")
        
        XCTAssertNotNil(aSample?.format)
        XCTAssertNotNil(aSample?.format?.details)
    }
    #endif

    
}
