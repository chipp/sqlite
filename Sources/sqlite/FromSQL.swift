import Foundation
import SQLite3

public protocol FromSQL {
    static func decode(from value: OpaquePointer) -> Self
}

extension String: FromSQL {
    public static func decode(from value: OpaquePointer) -> String {
        String(cString: sqlite3_value_text(value))
    }
}

extension Optional: FromSQL where Wrapped: FromSQL {
    public static func decode(from value: OpaquePointer) -> Wrapped? {
        let dataType = sqlite3_value_type(value)

        if dataType == SQLITE_NULL {
            return nil
        } else {
            return Wrapped.decode(from: value)
        }
    }
}

extension Bool: FromSQL {
    public static func decode(from value: OpaquePointer) -> Bool {
        sqlite3_value_int(value) != 0
    }
}

extension Int: FromSQL {
    public static func decode(from value: OpaquePointer) -> Int {
        Int(sqlite3_value_int64(value))
    }
}

extension Int8: FromSQL {
    public static func decode(from value: OpaquePointer) -> Int8 {
        Int8(sqlite3_value_int(value))
    }
}
