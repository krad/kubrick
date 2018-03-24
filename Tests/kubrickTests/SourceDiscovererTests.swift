import XCTest
@testable import kubrick

class SourceDiscovererTests: XCTestCase {

    func test_that_we_can_get_a_list_of_sources() {
        let mock    = MockSource()
        let subject = AVDeviceDiscoverer(mock)
        XCTAssertNotNil(subject.sources)
        XCTAssert(subject.sources.count > 0)
    }
    
    func test_that_we_can_get_a_list_of_devices() {
        let mock    = MockSource()
        let subject = AVDeviceDiscoverer(mock)
        XCTAssertNotNil(subject.devices)
        XCTAssert(subject.devices.count > 0)
    }
    
    #if os(macOS)
    func test_that_we_can_get_a_list_of_sources_on_macOS() {
        let subject = AVDeviceDiscoverer()
        XCTAssert(subject.sources.count > 0)
    }
    
    func test_that_we_can_get_a_list_of_devices_on_macOS() {
        let subject = AVDeviceDiscoverer()
        XCTAssert(subject.devices.count > 0)
    }
    
    func test_that_we_can_get_a_list_of_displays_on_macOS() {
        let subject = SystemMediaSource()
        XCTAssert(subject.displays().count > 0)
        
        let display = subject.displays().first
        XCTAssertEqual(display?.uniqueID, "2077751165")
        XCTAssertEqual(display?.devicePosition, .unspecified)
        XCTAssertEqual(display?.isConnected, true)
        XCTAssertEqual(display?.modelID, "40994")
        XCTAssertEqual(display?.localizedName, "Color LCD")
        XCTAssertEqual(display?.type, .video)
    }
    
    func test_that_we_can_get_a_list_of_display_devices_on_macOS() {
        let subject = AVDeviceDiscoverer()
        let display = subject.devices.last
        XCTAssertEqual(display?.source.localizedName, "Color LCD")
    }
    #endif
    
}
