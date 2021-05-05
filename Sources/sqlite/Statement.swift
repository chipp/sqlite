import Foundation
import SQLite3

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public struct Statement {
    let connection: Connection
    let raw: OpaquePointer

    @discardableResult
    public func execute(params: [ToSQL] = []) -> Result<Int, SQLiteError> {
        bindParameters(params).flatMap {
            step().flatMap { nextRowAvailable in
                if !nextRowAvailable {
                    sqlite3_reset(raw)
                    return .success(Int(sqlite3_changes(connection.dbHandle)))
                } else {
                    // TODO:
                    fatalError()
                }
            }
        }
    }

    public func query(params: [ToSQL] = []) -> Result<Rows, SQLiteError> {
        bindParameters(params).map {
            Rows(RowsIterator(statement: self))
        }
    }

    func step() -> Result<Bool, SQLiteError> {
        switch sqlite3_step(raw) {
        case SQLITE_ROW:
            return .success(true)
        case SQLITE_DONE:
            return .success(false)
        case let result:
            return .failure(SQLiteError(resultCode: result, connection: connection))
        }
    }

    func value(at column: Int) -> OpaquePointer {
        sqlite3_column_value(raw, Int32(column))
    }

    func bindParameters(_ params: [ToSQL]) -> Result<(), SQLiteError> {
        precondition(params.count == sqlite3_bind_parameter_count(raw))

        for (index, param) in params.enumerated() {
            let index = Int32(index) + 1

            let result: Int32

            switch param.sqliteInput {
            case .null:
                result = sqlite3_bind_null(raw, index)
            case let .int(value):
                result = sqlite3_bind_int(raw, index, value)
            case let .int64(value):
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
                return .failure(SQLiteError(resultCode: result, connection: connection))
            }
        }

        return .success(())
    }
}
