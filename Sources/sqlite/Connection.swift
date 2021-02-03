import Foundation
import SQLite3

public final class Connection {
    enum Error: Swift.Error {
        case unableToOpenSQLiteDb(Int32)
    }

    public static func open(_ fileURL: URL) throws -> Connection {
        var dbHandle: OpaquePointer?
        let result = fileURL.absoluteString.withCString { filename in
            withUnsafeMutablePointer(to: &dbHandle) { db in
                sqlite3_open(filename, db)
            }
        }

        if result == SQLITE_OK, let dbHandle = dbHandle {
            return Connection.init(dbHandle: dbHandle)
        } else {
            throw Error.unableToOpenSQLiteDb(result)
        }
    }

    let dbHandle: OpaquePointer
    init(dbHandle: OpaquePointer) {
        self.dbHandle = dbHandle
    }

    deinit {
        sqlite3_close(dbHandle)
    }

    public func prepare(sql: String) throws -> Result<Statement, SQLiteError> {
        sql.utf8CString.withUnsafeBufferPointer { sql -> Result<OpaquePointer, SQLiteError> in
            var stmt: OpaquePointer?
            let result = withUnsafeMutablePointer(to: &stmt) { stmt in
                sqlite3_prepare_v2(dbHandle, sql.baseAddress, Int32(sql.count), stmt, nil)
            }

            if result == SQLITE_OK, let stmt = stmt {
                return .success(stmt)
            } else {
                return .failure(SQLiteError(resultCode: result, connection: self))
            }
        }.map { Statement(connection: self, raw: $0) }
    }
}
