import Foundation

public enum SQLiteValue: Equatable {
    case null
    case int(Int)
    case real(Double)
    case text(String)
    case blob(Data)
}

extension SQLiteValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension SQLiteValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }
}

extension SQLiteValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .text(value)
    }
}

extension SQLiteValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self = .real(value)
    }
}

extension SQLiteValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .int(value ? 1 : 0)
    }
}
