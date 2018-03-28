import Dispatch

public class VideoReader: NSObject, MediaDeviceReader {

    public var q                     = DispatchQueue(label: "video.reader.q")
    public var mediaType             = MediaType.video
    public var sinks: [Sink<Sample>] = []
    
    public override init() { super.init() }
    
}

#if os(macOS) || os(iOS)
    import AVFoundation
    extension VideoReader: AVCaptureVideoDataOutputSampleBufferDelegate {
        public func captureOutput(_ output: AVCaptureOutput,
                                  didOutput sampleBuffer: CMSampleBuffer,
                                  from connection: AVCaptureConnection)
        {
            self.q.async {
                
                if let masterClock = connection.videoPreviewLayer.session?.masterClock {
                    let port            = connection.inputPorts.first
                    if let originalClock = port?.clock {
                        print("==============")
                        let syncedPTS   = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                        let originalPTS = CMSyncConvertTime(syncedPTS, masterClock, originalClock)
                        print(originalPTS)
                        print(syncedPTS)
                    }
                }
                
                self.push(input: sampleBuffer)
            }
        }        
    }
#endif
