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
