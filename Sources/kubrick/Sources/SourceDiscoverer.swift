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
    func devices(_ scope: MediaSourceScope) -> [MediaDevice]
    func sources(_ scope: MediaSourceScope) -> [Source]
}

public enum MediaSourceScope {
    case all
    case simple
}

/// Used to discover devices available to the system
public struct AVDeviceDiscoverer: SourceDiscoverer {
    
    public private(set) var mediaSource: MediaSource
    
    public init(_ mediaSource: MediaSource = SystemMediaSource()) {
        self.mediaSource = mediaSource
    }
    
    public var sources: [Source] { return mediaSource.sources() }
    public var devices: [MediaDevice] { return mediaSource.devices() }
    
    public func devices(scoped: MediaSourceScope) -> [MediaDevice] {
        return mediaSource.devices(scoped)
    }
}

public struct SystemMediaSource {
    public init() { }
}

extension MediaSource {
    public func devices() -> [MediaDevice] {
        return self.devices(.all)
    }
    
    public func devices(_ scope: MediaSourceScope) -> [MediaDevice] {
        return self.sources(scope).flatMap {
            switch $0.type {
            case .video?: return Camera($0)
            case .audio?: return Microphone($0)
            case .none:   return nil
            }
        }
    }
}

#if os(macOS)
    extension SystemMediaSource: MediaSource {
        
        public func sources() -> [Source] {
            let srcs: [[Source]] = [AVCaptureDevice.devices(), self.displays()]
            return srcs.flatMap { $0 }
        }
        
        public func sources(_ scope: MediaSourceScope) -> [Source] {
            return self.sources()
        }
        
        internal func displayIDs() -> [CGDirectDisplayID] {
            // If you have more than 10 screens, please send me a pic of your setup.
            let maxDisplays          = 10
            var displays             = [CGDirectDisplayID](repeating: 0, count: maxDisplays)
            var displayCount: UInt32 = 0
            
            CGGetOnlineDisplayList(UInt32(maxDisplays), &displays, &displayCount)
            return Array(displays[0..<Int(displayCount)])
        }
        
        public func displays() -> [DisplaySource] {
            return self.displayIDs().flatMap { DisplaySource($0) }
        }
    }
#endif

#if os(iOS)
    extension SystemMediaSource: MediaSource {
        public func sources() -> [Source] {
            return self.sources(.all)
        }
        
        public func sources(_ scope: MediaSourceScope) -> [Source] {
            let types = self.types(with: scope)
            let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: types,
                                                             mediaType: nil,
                                                             position: .unspecified)
            return discovery.devices
        }
        
        internal func types(with scope: MediaSourceScope) -> [AVCaptureDevice.DeviceType] {
            var types: [AVCaptureDevice.DeviceType] = [.builtInMicrophone, .builtInWideAngleCamera]
            
            switch scope {
            case .all:
                types.append(.builtInTelephotoCamera)
                if #available(iOS 10.2, *) { types.append(.builtInDualCamera) }
                else { types.append(.builtInDuoCamera) }
                if #available(iOS 11.1, *) { types.append(.builtInTrueDepthCamera) }

                return types
            case .simple:
                return types
            }
        }
    }
#endif
