import Foundation
import SQLite3

public final class Connection {
    public static func open(_ fileURL: URL) -> Result<Connection, SQLiteError> {
        var dbHandle: OpaquePointer?
        let result = fileURL.absoluteString.withCString { filename in
            withUnsafeMutablePointer(to: &dbHandle) { db in
                sqlite3_open(filename, db)
            }
        }

        switch (result, dbHandle) {
        case (SQLITE_OK, let dbHandle?):
            return .success(Connection(dbHandle: dbHandle))
        case (let resultCode, _):
            return .failure(SQLiteError(resultCode: resultCode, connection: dbHandle.map(Connection.init)))
        }
    }

    let dbHandle: OpaquePointer
    init(dbHandle: OpaquePointer) {
        self.dbHandle = dbHandle
    }

    deinit {
        sqlite3_close(dbHandle)
    }

    public func prepare(sql: String) -> Result<Statement, SQLiteError> {
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
