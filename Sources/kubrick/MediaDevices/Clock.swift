public protocol Clock { }

#if os(iOS) || os(macOS)
    import AVFoundation
    extension CMClock: Clock { }
#endif
