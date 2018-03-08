import XCTest
@testable import kubrick
import grip

class StreamTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }
    
    class MockEndpoint: Writeable {
        var samples: [Data] = []
        func write(_ data: Data) {
            samples.append(data)
        }
    }
    
    func test_that_we_can_create_a_new_session_without_exploding() {
        let src       = MockSource()
        let discovery = AVDeviceDiscoverer(src)
        XCTAssert(discovery.devices.count > 0)
        XCTAssertNoThrow(try AVStream(devices: discovery.devices))
        
        let stream = try? AVStream(devices: discovery.devices)
        XCTAssertNotNil(stream)
        XCTAssertEqual(stream?.devices.count, discovery.devices.count)
        XCTAssertEqual(stream?.readers.count, discovery.devices.count)
        
        XCTAssertNotNil(stream?.videoEncoderSink)
        XCTAssertNotNil(stream?.audioEncoderSink)
        
        XCTAssertEqual(1, stream?.videoEncoderSink?.nextSinks.count)
        XCTAssertEqual(1, stream?.audioEncoderSink?.nextSinks.count)
        XCTAssertNil(stream?.endPointSink)
    }
    
    #if os(macOS)
    func test_that_we_can_walk_through_a_stream_session() {
        useRealDeviceIO()
        
        let discovery = AVDeviceDiscoverer()
        let video = discovery.devices.filter { $0.source.type == .video }.first
        let audio = discovery.devices.filter { $0.source.type == .audio }.first
        
        XCTAssertNotNil(video)
        XCTAssertNotNil(audio)
        
        let stream   = try? AVStream(devices: [video!, audio!])
        let endpoint = MockEndpoint()
        XCTAssertNotNil(stream)

        XCTAssertNil(stream?.muxSink.videoFormat)
        XCTAssertNil(stream?.muxSink.audioFormat)

        XCTAssertEqual(1, stream?.videoEncoderSink?.nextSinks.count)
        XCTAssertEqual(1, stream?.audioEncoderSink?.nextSinks.count)
        XCTAssertEqual(0, endpoint.samples.count)
        
        stream?.session.startRunning()
        stream?.set(endpoint: endpoint)
        
        let e = self.expectation(description: "Ensure we get data to the endpoint")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { e.fulfill() }
        self.wait(for: [e], timeout: 3)

        XCTAssertNotNil(stream?.muxSink.videoFormat)
        XCTAssertNotNil(stream?.muxSink.audioFormat)

        XCTAssert(endpoint.samples.count > 1)
        
    }
    #endif
    
}
