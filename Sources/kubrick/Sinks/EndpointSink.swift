import grip
import Foundation

public class EndpointSink: Sink<BinaryEncodable> {

    var endpoint: Writeable
    
    init(_ endpoint: Writeable) {
        self.endpoint = endpoint
    }
    
    public override func push(input: BinaryEncodable) {
        do {
            let bytes = try BinaryEncoder.encode(input)
            print(#function, "Writing: ", bytes.count)
            self.endpoint.write(Data(bytes))
        } catch let err {
            print("Could not encode input:", err)
        }
    }
    
}
