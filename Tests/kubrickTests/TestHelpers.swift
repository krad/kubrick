@testable import kubrick

let realMakeInput   = kubrick.makeInput
let realMakeOutput  = kubrick.makeOutput

func useRealDeviceIO() {
    kubrick.makeInput  = realMakeInput
    kubrick.makeOutput = realMakeOutput
}

func useMockDeviceIO() {
    kubrick.makeInput  = makeInputMock
    kubrick.makeOutput = makeOutputMock
}

