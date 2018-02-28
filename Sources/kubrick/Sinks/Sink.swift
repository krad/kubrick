import Dispatch

public enum SinkError: Error {
    case incompatibleMediaType
}

/// Sink is a abstract base type for adopting the SinkProtocol
open class Sink<In>: SinkProtocol {
    public typealias InputType  = In
    
    open func push(input: In) {
        print(#function, "Override the push input in class that inherits from Sink")
    }
    
}

/// Sink protocol defines a class that can accept some type of input for processing
public protocol SinkProtocol {
    associatedtype InputType
    func push(input: InputType)
}

/// NextSinkProtocol should be adopted by a Sink when it has some processing it needs to pass on
public protocol NextSinkProtocol {
    associatedtype OutputType
    var nextSinks: [Sink<OutputType>] { get }
}
