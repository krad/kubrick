import Foundation

public class ThreadSafeArray<T>: Collection {
    
    public var startIndex: Int = 0
    public var endIndex: Int { return self.count }
    
    private var array: [T] = []
    private let q = DispatchQueue(label: "threadSafeArray.q",
                                  qos: .default,
                                  attributes: .concurrent,
                                  autoreleaseFrequency: .inherit,
                                  target: nil)
    
    public func append(_ newElement: T) {
        q.async(flags: .barrier) { self.array.append(newElement) }
    }
    
    public func append(contentsOf: [T]) {
        q.async(flags: .barrier) { self.array.append(contentsOf: contentsOf) }
    }
    
    public func remove(at index: Int) {
        q.async(flags: .barrier) { self.array.remove(at: index) }
    }
    
    public func removeFirst(n: Int) {
        q.async(flags: .barrier) { self.array.removeFirst(n) }
    }
    
    public func removeLast() {
        q.async(flags: .barrier) { self.array.removeLast() }
    }
    
    public func removeLast(n: Int) {
        q.async(flags: .barrier) { self.array.removeLast(n) }
    }
    
    public var count: Int {
        var count = 0
        q.sync { count = self.array.count }
        return count
    }
    
    public var first: T? {
        var element: T?
        q.sync { element = self.array.first }
        return element
    }
    
    public func prefix(_ maxLength: Int) -> [T]? {
        var result: [T]?
        q.sync { result = Array(self.array.prefix(maxLength)) }
        return result
    }
    
    public var last: T? {
        var element: T?
        q.sync { element = self.array.last }
        return element
    }
    
    public func index(after i: Int) -> Int {
        var index: Int = 0
        q.sync { index = self.array.index(after: i) }
        return index
    }
    
    public subscript(index: Int) -> T {
        set {
            q.async(flags: .barrier) { self.array[index] = newValue }
        }
        
        get {
            var element: T!
            q.sync { element = self.array[index] }
            return element
        }
    }
    
}

