import Foundation
import SQLite3

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public class Statement {
    let connection: Connection
    let raw: OpaquePointer

    init(connection: Connection, raw: OpaquePointer) {
        self.connection = connection
        self.raw = raw
    }

    deinit {
        sqlite3_finalize(raw)
    }

    @discardableResult
    public func execute(params: [ToSQL] = []) throws -> Int {
        try bindParameters(params)
        let nextRowAvailable = try step()

        if !nextRowAvailable {
            sqlite3_reset(raw)
            return Int(sqlite3_changes(connection.dbHandle))
        } else {
            // TODO:
            fatalError()
        }
    }

    public func query(params: [ToSQL] = []) throws -> Rows {
        try bindParameters(params)
        return Rows(statement: self)
    }

    public func reset() {
        sqlite3_reset(raw)
    }

    func step() throws -> Bool {
        switch sqlite3_step(raw) {
        case SQLITE_ROW:
            return true
        case SQLITE_DONE:
            return false
        case let result:
            throw SQLiteError(resultCode: result, connection: connection)
        }
    }

    func value(at column: Int) -> OpaquePointer {
        sqlite3_column_value(raw, Int32(column))
    }

    func bindParameters(_ params: [ToSQL]) throws {
        precondition(params.count == sqlite3_bind_parameter_count(raw))

        for (index, param) in params.enumerated() {
            let index = Int32(index) + 1

            let result: Int32

            switch param.encode {
            case .null:
                result = sqlite3_bind_null(raw, index)
            case let .int(value):
                result = sqlite3_bind_int64(raw, index, Int64(value))
            case let .real(value):
                result = sqlite3_bind_double(raw, index, value)
            case let .text(value):
                result = sqlite3_bind_text(raw, index, value, -1, SQLITE_TRANSIENT)
            case let .blob(value):
                if value.isEmpty {
                    result = sqlite3_bind_zeroblob(raw, index, 0)
                } else {
                    result = value.withUnsafeBytes { value in
                        sqlite3_bind_blob(raw, index, value.baseAddress, Int32(value.count), SQLITE_TRANSIENT)
                    }
                }
            }

            if result != SQLITE_OK {
                throw SQLiteError(resultCode: result, connection: connection)
            }
        }
    }
}
