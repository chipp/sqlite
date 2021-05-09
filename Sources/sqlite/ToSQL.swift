import Foundation
import SQLite3

public enum SQLiteInput {
    case null
    case int(Int32)
    case int64(Int)
    case real(Double)
    case text(String)
    case blob(Data)
}

extension SQLiteInput: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension SQLiteInput: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .int64(value)
    }
}

extension SQLiteInput: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .text(value)
    }
}

extension SQLiteInput: ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self = .real(value)
    }
}

extension SQLiteInput: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .int(value ? 1 : 0)
    }
}

extension SQLiteInput: ToSQL {
    public var sqliteInput: SQLiteInput { self }
}

public protocol ToSQL {
    var sqliteInput: SQLiteInput { get }
}

extension UUID: ToSQL {
    public var sqliteInput: SQLiteInput {
        .blob(withUnsafeBytes(of: uuid) { pointer in
            Data(bytes: pointer.baseAddress!, count: pointer.count)
        })
    }
}

extension String: ToSQL {
    public var sqliteInput: SQLiteInput { .text(self) }
}

extension RawRepresentable where Self: ToSQL, RawValue: ToSQL {
    public var sqliteInput: SQLiteInput { rawValue.sqliteInput }
}

extension Data: ToSQL {
    public var sqliteInput: SQLiteInput {
        .blob(self)
    }
}
