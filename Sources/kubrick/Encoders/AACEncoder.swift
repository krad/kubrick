import Foundation
import AudioToolbox
import CoreMedia
import Dispatch

#if os(macOS) || os(iOS)
internal class AACEncoder: AudioEncoder {
    
    public var configured: Bool = false
    private var audioConverter: AudioConverterRef?

    public init() {
        self.audioConverter = nil
    }

    func setup(using sample: Sample) {
        
    }
    
    func encode(_ sample: Sample, onComplete: ([UInt8]?, Rational?) -> Void) {
        
    }
    
    
    ////////////////////////////////////////////////////////////
    //////////// LEGACY
    ////////////////////////////////////////////////////////////
    
    private var encoderQ  = DispatchQueue(label: "aac.encoder.q")
    private var callbackQ = DispatchQueue(label: "aac.encoder.callback.q")
    
    fileprivate var aacBuffer: [UInt8] = []
    private var pcmBuffer = ThreadSafeArray<UInt8>()
    private var numberOfSamplesInBuffer: Int = 0
    
    private var inASBD: AudioStreamBasicDescription?
    private var outASBD: AudioStreamBasicDescription?
    
    private var previousDuration = kCMTimeZero
    private var makeBytesStereo = false
    
    fileprivate var fillComplexCallback: AudioConverterComplexInputDataProc = { (inAudioConverter,
        ioDataPacketCount, ioData, outDataPacketDescriptionPtrPtr, inUserData) in
        return Unmanaged<AACEncoder>.fromOpaque(inUserData!).takeUnretainedValue().audioConverterCallback(
            ioDataPacketCount,
            ioData: ioData,
            outDataPacketDescription: outDataPacketDescriptionPtrPtr
        )
    }
    
    func setupEncoder(from sampleBuffer: CMSampleBuffer) {
        
        if let format = CMSampleBufferGetFormatDescription(sampleBuffer) {
            if var inASBD = CMAudioFormatDescriptionGetStreamBasicDescription(format)?.pointee {
                
                /// The iPhone only records in mono.
                /// This will choke HLS streams.
                /// The AVFoundation class of HLS tools ignores header config information in the mp4a atom
                /// This means that while you can reliably encode mono HLS streams, you can't get them to reliably play.
                /// The solution is to make the mono stream stereo by copying the pcm bytes before passing them to the AAC encoder
                /// This is extremely naive, but it works and opens up some interesting possibilities I may explore.
                if inASBD.mChannelsPerFrame == 1 {
                    inASBD.mBytesPerPacket   = inASBD.mBytesPerPacket * 2
                    inASBD.mBytesPerFrame    = inASBD.mBytesPerFrame  * 2
                    inASBD.mChannelsPerFrame = 2
                    self.makeBytesStereo     = true
                }
                
                var outASBD                 = AudioStreamBasicDescription()
                outASBD.mSampleRate         = inASBD.mSampleRate
                outASBD.mFormatID           = kAudioFormatMPEG4AAC
                outASBD.mFormatFlags        = UInt32(MPEG4ObjectID.AAC_LC.rawValue)
                outASBD.mBytesPerPacket     = 0
                outASBD.mFramesPerPacket    = 1024
                outASBD.mBytesPerFrame      = 0
                outASBD.mChannelsPerFrame   = inASBD.mChannelsPerFrame
                outASBD.mBitsPerChannel     = 0
                outASBD.mReserved           = 0
                self.outASBD                = outASBD
                self.inASBD                 = inASBD
                
                #if os(macOS)
                    let status = AudioConverterNew(&inASBD, &outASBD, &audioConverter)
                    if status != noErr { print("Failed to setup converter:", status) }
                #else
                    if var description = getAudioClassDescription() {
                        let status = AudioConverterNewSpecific(&inASBD,
                                                               &outASBD,
                                                               1,
                                                               &description,
                                                               &audioConverter)
                        if status != noErr { print("Failed to setup converter:", status) }
                    } else {
                        print("Couldn't get audio converter description")
                    }
                #endif
            }
        }
    }
    
    public func encode(_ sampleBuffer: CMSampleBuffer,
                       onComplete: @escaping ([UInt8]?, OSStatus, CMTime?) -> Void)
    {
        self.encoderQ.async {
            if self.audioConverter == nil { self.setupEncoder(from: sampleBuffer) }
            guard let audioConverter = self.audioConverter else { return }
            
            let numberOfSamples         = CMSampleBufferGetNumSamples(sampleBuffer)
            let duration                = CMSampleBufferGetDuration(sampleBuffer)
            var pcmBufferSize: UInt32   = 0
            
            if let sampleBytes = getBytes(from: sampleBuffer) {
                
                if self.makeBytesStereo {
                    
                    var actualSamples: [Int16] = []
                    
                    /// Build an array of 16 bit samples
                    stride(from: 0, to: sampleBytes.count, by: 2).forEach({ idx in
                        if let result = Int16(bytes: [sampleBytes[idx], sampleBytes[idx+1]]) {
                            actualSamples.append(result)
                        }
                    })
                    
                    let stereoized = zip(actualSamples, actualSamples).flatMap { [$0, $1] }
                    let results: [UInt8] = stereoized.flatMap { byteArray(from: $0) }
                    
                    self.pcmBuffer.append(contentsOf: results)
                    
                } else {
                    self.pcmBuffer.append(contentsOf: sampleBytes)
                }
                
                self.numberOfSamplesInBuffer += numberOfSamples
                
                if self.numberOfSamplesInBuffer < 1024 {
                    self.previousDuration = duration
                    return
                }
                
                pcmBufferSize = UInt32(self.pcmBuffer.count)
            }
            
            self.aacBuffer = [UInt8](repeating: 0, count: Int(pcmBufferSize))
            
            let outBuffer                   = AudioBufferList.allocate(maximumBuffers: 1)
            outBuffer[0].mNumberChannels    = self.outASBD!.mChannelsPerFrame
            outBuffer[0].mDataByteSize      = pcmBufferSize
            
            self.aacBuffer.withUnsafeMutableBytes({ rawBufPtr in
                let ptr = rawBufPtr.baseAddress
                outBuffer[0].mData = ptr
            })
            
            var ioOutputDataPacketSize: UInt32 = 1
            
            let status = AudioConverterFillComplexBuffer(audioConverter,
                                                         self.fillComplexCallback,
                                                         Unmanaged.passUnretained(self).toOpaque(),
                                                         &ioOutputDataPacketSize,
                                                         outBuffer.unsafeMutablePointer,
                                                         nil)
            
            switch status {
            case noErr:
                let aacPayload = Array(self.aacBuffer[0..<Int(outBuffer[0].mDataByteSize)])
                onComplete(aacPayload, noErr, duration)
            case -1:
                print("Needed more bytes")
            default:
                print("Error converting buffer:", status)
                onComplete(nil, status, nil)
            }
        }
    }
    
    
    fileprivate func audioConverterCallback(
        _ ioNumberDataPackets: UnsafeMutablePointer<UInt32>,
        ioData: UnsafeMutablePointer<AudioBufferList>,
        outDataPacketDescription: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?) -> OSStatus
    {
        let requestedPackets = ioNumberDataPackets.pointee
        
        var pcmBufferSize: UInt32 = 0
        if var pcmBuffer = self.pcmBuffer.prefix(self.pcmBuffer.count) {
            
            pcmBufferSize = UInt32(pcmBuffer.count)
            pcmBuffer.withUnsafeMutableBufferPointer { bufferPtr in
                let ptr                               = UnsafeMutableRawPointer(bufferPtr.baseAddress)
                ioData.pointee.mBuffers.mData         = ptr
                ioData.pointee.mBuffers.mDataByteSize = pcmBufferSize
            }
            
        } else {
            ioNumberDataPackets.pointee = 0
            return -1
        }
        
        if pcmBufferSize < requestedPackets {
            ioNumberDataPackets.pointee = 0
            return -1
        }
        
        self.pcmBuffer.removeFirst(n: Int(pcmBufferSize))
        self.numberOfSamplesInBuffer -= 1024
        ioNumberDataPackets.pointee = 1
        return noErr
    }
    
}
#endif

#if os(iOS)
    internal func getAudioClassDescription() -> AudioClassDescription? {
        var encoderSpecifier        = kAudioFormatMPEG4AAC
        var encoderSpecSize: UInt32 = 0
        
        var status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                                UInt32(MemoryLayout.size(ofValue: encoderSpecifier)),
                                                &encoderSpecifier,
                                                &encoderSpecSize)
        
        if status != noErr {
            print("Error getting available encoders:", status)
            return nil
        }
        
        let numEncoders = Int(encoderSpecSize) / MemoryLayout<AudioClassDescription>.size
        let ptr = UnsafeMutableRawPointer.allocate(bytes: numEncoders, alignedTo: 0)
        
        status = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                        UInt32(MemoryLayout.size(ofValue: encoderSpecifier)),
                                        &encoderSpecifier,
                                        &encoderSpecSize,
                                        ptr)
        
        if status != noErr {
            print("Error getting available encoder descriptions:", status)
            return nil
        }
        
        let buffPtr = UnsafeBufferPointer(start: ptr.assumingMemoryBound(to: AudioClassDescription.self),
                                          count: numEncoders)
        
        let encoderDescriptions = Array(buffPtr)
        for description in encoderDescriptions {
            if description.mSubType == kAudioFormatMPEG4AAC {
                if description.mManufacturer == kAppleSoftwareAudioCodecManufacturer {
                    return description
                }
            }
        }
        return nil
    }
#endif


