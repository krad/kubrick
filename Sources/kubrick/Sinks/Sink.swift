import Dispatch

public enum SinkError: Error {
    case incompatibleMediaType
}

public class Sink<IN>: SinkProtocol {
    public typealias InputType  = IN
    
    open var nextSinks: [Sink] = []
    
    open func push(input: IN) {
        print(#function, "Override the push input in class that inherits from Sink")
    }
    
}


public protocol SinkProtocol {
    associatedtype InputType
    func push(input: InputType)
}
