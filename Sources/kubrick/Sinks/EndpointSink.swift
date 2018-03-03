import grip
import Foundation

public class EndpointSink: Sink<BinaryEncodable> {

    var endpoint: Writeable
    
    public init(_ endpoint: Writeable) {
        self.endpoint = endpoint
    }
    
    public override func push(input: BinaryEncodable) {
        do {
            let bytes = try BinaryEncoder.encode(input)
            self.endpoint.write(Data(bytes))
        } catch let err {
            print("Could not encode input:", err)
        }
    }
    
}
