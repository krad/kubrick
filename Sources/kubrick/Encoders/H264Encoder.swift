#if os(macOS) || os(iOS)
import VideoToolbox
#endif

internal class H264Encoder: VideoEncoder {
    
    fileprivate var settings: H264Settings
    
    fileprivate var samples     = ThreadSafeArray<Sample>()
    fileprivate var callbacks   = ThreadSafeArray<VideoEncodedCallback>()
    
    init(_ settings: H264Settings) throws {
        self.settings = settings
        try self.configure()
    }
    
    #if os(macOS) || os(iOS)
    fileprivate var session: VTCompressionSession?
    
    fileprivate var encodeCallback: VTCompressionOutputCallback = {outputRef, sourceFrameRef, status, infoFlags, sampleBuffer in
        let encoder: H264Encoder = unsafeBitCast(outputRef, to: H264Encoder.self)
        if status == noErr {
            if let sb = sampleBuffer {
                if let callback = encoder.callbacks.first {
                    callback(sb)
                    encoder.callbacks.removeFirst(n: 1)
                }
            }
        }
    }

    func configure() throws {
        var status = noErr
        var encoderSpec: CFDictionary?
        #if os(macOS)
            encoderSpec = [kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder as String: true] as CFDictionary
        #endif
        
        let imageBufferAttributes: [NSString: AnyObject] =
            [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange as AnyObject,
             kCVPixelBufferWidthKey: NSNumber(value: settings.width),
            kCVPixelBufferHeightKey: NSNumber(value: settings.height)]
        
        
        status = VTCompressionSessionCreate(kCFAllocatorDefault,
                                            Int32(settings.width),
                                            Int32(settings.height),
                                            kCMVideoCodecType_H264,
                                            encoderSpec,
                                            imageBufferAttributes as CFDictionary?,
                                            nil,
                                            self.encodeCallback,
                                            unsafeBitCast(self, to: UnsafeMutableRawPointer.self),
                                            &self.session)

        if status == noErr {
            
            let ctrue = true as CFBoolean
            let cfalse = false as CFBoolean
            
            VTSessionSetProperty(session!, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, 2 as CFTypeRef)
            VTSessionSetProperty(session!, kVTCompressionPropertyKey_RealTime, ctrue)
            VTSessionSetProperty(session!, kVTCompressionPropertyKey_ExpectedFrameRate, settings.frameRate as CFTypeRef)
            VTSessionSetProperty(session!, kVTCompressionPropertyKey_AllowFrameReordering, cfalse)
            
            VTSessionSetProperty(session!, kVTCompressionPropertyKey_AllowTemporalCompression, ctrue)
            
            VTSessionSetProperty(session!, kVTCompressionPropertyKey_ProfileLevel, settings.profile.raw)
            VTSessionSetProperty(session!, kVTCompressionPropertyKey_DataRateLimits, 110_000 as CFTypeRef)
        } else {
            throw VideoEncoderError.failedSetup
        }
    }
    
    func encode(_ sample: Sample, onComplete: @escaping VideoEncodedCallback) {
        
        if sample.duration.time.value <= 0 {
            if let previousSample = self.samples.first {
                let prevPTS         = previousSample.pts.time
                let currPTS         = sample.pts.time
                let durationDiff    = CMTimeSubtract(prevPTS, currPTS)
                let duration        = CMTimeConvertScale(durationDiff,
                                                         Int32(self.settings.frameRate)*1000,
                                                         .quickTime)
                self.samples.removeFirst(n: 1)
                self.process(previousSample, duration: duration)
                print("============")
                print(duration)
                print(durationDiff)
            }
            
            self.samples.append(sample)
            self.callbacks.append(onComplete)
            
        } else {
            self.callbacks.append(onComplete)
            self.process(sample, duration: sample.duration.time)
        }
    }
    
    private func process(_ sample: Sample, duration: CMTime) {
        let cmsample = sample as! CMSampleBuffer
        if let pixelBuffer = CMSampleBufferGetImageBuffer(cmsample) {
            VTCompressionSessionEncodeFrame(self.session!,
                                            pixelBuffer,
                                            sample.pts.time,
                                            duration,
                                            nil,
                                            nil,
                                            nil)
        }
    }
    
    #else
    func configure() { showNotAvailable() }
    func encode(_ sample: Sample, onComplete: @escaping VideoEncodedCallback) { showNotAvailable() }
    func showNotAvailable() { print("H264 Encoding not available on this platform") }
    #endif
}


