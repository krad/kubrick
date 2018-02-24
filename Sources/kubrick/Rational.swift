public struct Rational {
    public let numerator: Int64
    public let denominator: Int32
}

extension Rational: Hashable {
    public var hashValue: Int {
        return Int(self.numerator ^ Int64(self.denominator))
    }
    
    public static func ==(lhs: Rational, rhs: Rational) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
