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
    #endif
    
}
