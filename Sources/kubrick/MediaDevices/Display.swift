public class Display: MediaDevice {
    public var source: Source
    public var input: MediaDeviceInput?
    public var output: MediaDeviceOutput?
    public var reader: MediaDeviceReader?
    
    init(_ source: Source) {
        self.source = source
    }
}

#if os(macOS)
    import AVFoundation

    public struct DisplaySource: Source {
        
        public var uniqueID: String
        public var devicePosition: DevicePosition
        public var isConnected: Bool
        public var modelID: String
        public var localizedName: String
        public var type: MediaType?
        public var deviceFormats: [DeviceFormat]
        
        init(_ displayID: CGDirectDisplayID) {
            self.uniqueID       = "\(displayID)"
            self.devicePosition = .unspecified
            self.isConnected    = true
            self.modelID        = "\(CGDisplayModelNumber(displayID))"
            self.localizedName  = "\(displayName(for: displayID))"
            self.type           = .video
            self.deviceFormats  = []
        }
        
    }
    
    internal func displayName(for displayID: CGDirectDisplayID) -> String {
        
        var result = ""
        var object : io_object_t
        var serialPortIterator = io_iterator_t()
        let matching = IOServiceMatching("IODisplayConnect")
        
        let kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                      matching,
                                                      &serialPortIterator)
        if KERN_SUCCESS == kernResult && serialPortIterator != 0 {
            repeat {
                object = IOIteratorNext(serialPortIterator)
                
                let info = IODisplayCreateInfoDictionary(object, UInt32(kIODisplayOnlyPreferredName)).takeRetainedValue() as NSDictionary as! [String : AnyObject]
                
                let vendorID     = info[kDisplayVendorID] as? UInt32
                let productID    = info[kDisplayProductID] as? UInt32
                
                if vendorID == CGDisplayVendorNumber(displayID) {
                    if productID == CGDisplayModelNumber(displayID) {
                        if let productNameLocalizationDict = info[kDisplayProductName] as? [String: String] {
                            let pre = Locale.autoupdatingCurrent
                            if let language = pre.languageCode,
                                let region = pre.regionCode {
                                if let name = productNameLocalizationDict["\(language)_\(region)"] {
                                    result = name
                                }
                            }
                        }
                    }
                }
                
            } while object != 0
        }
        IOObjectRelease(serialPortIterator)
        
        return result
    }

#endif
