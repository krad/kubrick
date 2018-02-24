@testable import kubrick
#if os(macOS) || os(iOS)
    import AVFoundation
#endif

func useRealDeviceIO() {
    #if os(macOS) || os(iOS)
        kubrick.makeInput = { src, onCreate in
            let input = try AVCaptureDeviceInput.makeInput(device: src)
            onCreate(input)
            return input
        }
        
        kubrick.makeOutput =  { src, onCreate in
            switch src.type {
            case .video?:
                let output = AVCaptureVideoDataOutput()
                onCreate(output)
                return output
            case .audio?:
                let output = AVCaptureAudioDataOutput()
                #if os(macOS)
                    output.audioSettings = [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                        AVLinearPCMBitDepthKey: 16,
                        AVLinearPCMIsFloatKey: false,
                        AVLinearPCMIsNonInterleaved: false,
                    ]
                #endif

                onCreate(output)
                return output
            case .none:
                return nil
            }
        }
    #endif
}

func useMockDeviceIO() {
    kubrick.makeInput  = makeInputMock
    kubrick.makeOutput = makeOutputMock
}

