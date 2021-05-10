import Foundation
import SQLite3

public protocol ToSQL {
    var encode: SQLiteValue { get }
}

extension SQLiteValue: ToSQL {
    public var encode: SQLiteValue { self }
}

extension Int: ToSQL {
    public var encode: SQLiteValue {
        .int(self)
    }
}

extension Double: ToSQL {
    public var encode: SQLiteValue {
        .real(self)
    }
}

extension Bool: ToSQL {
    public var encode: SQLiteValue {
        .int(self ? 1 : 0)
    }
}

extension Optional: ToSQL where Wrapped: ToSQL {
    public var encode: SQLiteValue {
        guard let value = self?.encode else {
            return .null
        }

        return value
    }
}

extension UUID: ToSQL {
    public var encode: SQLiteValue {
        .blob(withUnsafeBytes(of: uuid) { pointer in
            Data(bytes: pointer.baseAddress!, count: pointer.count)
        })
    }
}

extension String: ToSQL {
    public var encode: SQLiteValue { .text(self) }
}

extension RawRepresentable where Self: ToSQL, RawValue: ToSQL {
    public var encode: SQLiteValue { rawValue.encode }
}

extension Data: ToSQL {
    public var encode: SQLiteValue {
        .blob(self)
    }
}
