#if os(macOS) || os(iOS)
    import CoreMedia
    
    internal func getBytes(from sample: CMSampleBuffer) -> [UInt8]? {
        if let dataBuffer = CMSampleBufferGetDataBuffer(sample) {
            var bufferLength: Int = 0
            var bufferDataPointer: UnsafeMutablePointer<Int8>? = nil
            CMBlockBufferGetDataPointer(dataBuffer, 0, nil, &bufferLength, &bufferDataPointer)
            
            var nalu = [UInt8](repeating: 0, count: bufferLength)
            CMBlockBufferCopyDataBytes(dataBuffer, 0, bufferLength, &nalu)
            return nalu
        }
        
        return nil
    }
    
#endif

public extension UInt32 {
    init?(bytes: [UInt8]) {
        if bytes.count != 4 { return nil }
        
        var value: UInt32 = 0
        for byte in bytes {
            value = value << 8
            value = value | UInt32(byte)
        }
        self = value
    }
}

public extension Int64 {
    init?(bytes: [UInt8]) {
        if bytes.count != 8 { return nil }
        
        var value: Int64 = 0
        for byte in bytes {
            value = value << 8
            value = value | Int64(byte)
        }
        self = value
    }
}

public extension Int16 {
    init?(bytes: [UInt8]) {
        if bytes.count != 2 { return nil }
        
        var value: Int16 = 0
        for byte in bytes {
            value = value << 8
            value = value | Int16(byte)
        }
        self = value
    }
}

public func byteArray(from uint16: UInt16) -> [UInt8] {
    var bigEndian = uint16.bigEndian
    let count = MemoryLayout<UInt16>.size
    let bytePtr = withUnsafePointer(to: &bigEndian) {
        $0.withMemoryRebound(to: UInt8.self, capacity: count) {
            UnsafeBufferPointer(start: $0, count: count)
        }
    }
    return Array(bytePtr)
}

public func byteArray(from int16: Int16) -> [UInt8] {
    var bigEndian = int16.bigEndian
    let count = MemoryLayout<Int16>.size
    let bytePtr = withUnsafePointer(to: &bigEndian) {
        $0.withMemoryRebound(to: UInt8.self, capacity: count) {
            UnsafeBufferPointer(start: $0, count: count)
        }
    }
    return Array(bytePtr)
}


public func byteArray(from uint32: UInt32) -> [UInt8] {
    var bigEndian = uint32.bigEndian
    let count = MemoryLayout<UInt32>.size
    let bytePtr = withUnsafePointer(to: &bigEndian) {
        $0.withMemoryRebound(to: UInt8.self, capacity: count) {
            UnsafeBufferPointer(start: $0, count: count)
        }
    }
    return Array(bytePtr)
}

public func byteArray(from int64: Int64) -> [UInt8] {
    var bigEndian = int64.bigEndian
    let count = MemoryLayout<Int64>.size
    let bytePtr = withUnsafePointer(to: &bigEndian) {
        $0.withMemoryRebound(to: UInt8.self, capacity: count) {
            UnsafeBufferPointer(start: $0, count: count)
        }
    }
    return Array(bytePtr)
}

extension Data {
    
    var bytes: [UInt8] {
        var bytes = [UInt8](repeating: 0, count: self.count)
        self.copyBytes(to: &bytes, count: self.count)
        return bytes
    }
    
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
