#if os(macOS) || os(iOS)
    import AVFoundation
#endif

public protocol SourceDiscoverer {
    var mediaSource: MediaSource { get }
    var sources: [Source] { get }
    var devices: [MediaDevice] { get }
}

public protocol MediaSource {
    func sources() -> [Source]
    func devices() -> [MediaDevice]
}

public struct AVDeviceDiscoverer: SourceDiscoverer {
    
    public private(set) var mediaSource: MediaSource
    
    init(_ mediaSource: MediaSource = SystemMediaSource()) {
        self.mediaSource = mediaSource
    }
    
    public var sources: [Source] {
        return mediaSource.sources()
    }
    
    public var devices: [MediaDevice] {
        return mediaSource.devices()
    }
    
}

public struct SystemMediaSource { }

extension MediaSource {
    public func devices() -> [MediaDevice] {
        return self.sources().flatMap {
            switch $0.type {
            case .video?:
                return Camera($0)
            case .audio?:
                return Microphone($0)
            case .none:
                return nil
            }
        }
    }
}

#if os(macOS)
    extension SystemMediaSource: MediaSource {
        public func sources() -> [Source] {
            return AVCaptureDevice.devices()
        }
    }
#endif

#if os(iOS)
    extension SystemMediaSource: MediaSource {
        public func sources() -> [Source] {
            var types: [AVCaptureDevice.DeviceType] = [.builtInMicrophone,
                                                       .builtInTelephotoCamera,
                                                       .builtInWideAngleCamera]
            
            //.builtInDualCamera,
            //.builtInDuoCamera,
            //.builtInTrueDepthCamera,

            let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: types,
                                                            mediaType: nil,
                                                            position: .unspecified)
            return discovery.devices
        }
    }
#endif
