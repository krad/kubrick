import Dispatch

public class VideoReader: NSObject, MediaDeviceReader {

    public var ident: String
    public var q                     = DispatchQueue(label: "video.reader.q")
    public var clock: Clock?
    public var mediaType             = MediaType.video
    public var sinks: [Sink<Sample>] = []
    
    public init(_ ident: String? = nil) {
        if let i = ident { self.ident = i }
        else { self.ident = UUID().uuidString }
    }
    
}

#if os(macOS) || os(iOS)
    import AVFoundation
    extension VideoReader: AVCaptureVideoDataOutputSampleBufferDelegate {
        public func captureOutput(_ output: AVCaptureOutput,
                                  didOutput sampleBuffer: CMSampleBuffer,
                                  from connection: AVCaptureConnection)
        {
            self.q.async {
                if let s = stripDecode(sampleBuffer) {
                    setSampleBufferAttachments(s, identifier: self.ident)
                    print(s)
                    self.push(input: s)
                }
            }
        }        
    }
#endif


func setSampleBufferAttachments(_ sampleBuffer: CMSampleBuffer, identifier: String) {
    let attachments: CFArray! = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true)
    let dictionary = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0),
                                   to: CFMutableDictionary.self)

//    let key   = Unmanaged.passUnretained("MediaDeviceReader.ident" as CFString).toOpaque()
//    let value = Unmanaged.passUnretained(identifier as CFString).toOpaque()
    let key = Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque()
    let value = Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
    CFDictionarySetValue(dictionary, key, value)
}


func stripDecode(_ sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
    var newSampleBuffer: CMSampleBuffer?
    var timingInfo = CMSampleTimingInfo(duration: CMSampleBufferGetDuration(sampleBuffer),
                                        presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer),
                                        decodeTimeStamp: kCMTimeInvalid)
    
    let status = CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault,
                                                       sampleBuffer,
                                                       1,
                                                       &timingInfo,
                                                       &newSampleBuffer)

    if status == noErr {
        return newSampleBuffer
    }
    
    return nil
}
