import Foundation
import SQLite3

public final class Connection {
    public static func open(_ fileURL: URL) -> Result<Connection, SQLiteError> {
        var dbHandle: OpaquePointer?
        let result = sqlite3_open(fileURL.absoluteString, &dbHandle)

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
        var stmt: OpaquePointer?
        let result = sqlite3_prepare_v2(dbHandle, sql, -1, &stmt, nil)

        if result == SQLITE_OK, let stmt = stmt {
            return .success(Statement(connection: self, raw: stmt))
        } else {
            return .failure(SQLiteError(resultCode: result, connection: self))
        }
    }
}
