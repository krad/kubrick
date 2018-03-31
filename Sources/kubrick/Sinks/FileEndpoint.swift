import Foundation
import grip


/// Endpoint that can be set on an AVStream object that will stream a/v sample data into a file
public final class FileEndpoint: Writeable, Endable {
    
    public var onEnd: EndedCallback?
    internal var continueWriting = true
    internal var fileHandle: FileHandle
    internal var writeQ = DispatchQueue(label: "fileEndpoint.q")
    
    public init(fileURL: URL, onEnd: EndedCallback?) throws {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
        
        self.onEnd = onEnd
        try self.fileHandle = FileHandle(forWritingTo: fileURL)
    }
    
    
    public func write(_ data: Data) {
        self.writeQ.async {
            if self.continueWriting {
                self.fileHandle.write(data)
            }
        }
    }
    
    public func end() {
        self.continueWriting = false
        self.fileHandle.closeFile()
        self.onEnd?(self)
    }
    
}
