import Foundation
import SQLite3

public final class Connection {
    public convenience init(_ fileURL: URL) throws {
        var dbHandle: OpaquePointer?
        let result = sqlite3_open(fileURL.absoluteString, &dbHandle)

        switch (result, dbHandle) {
        case (SQLITE_OK, let dbHandle?):
            self.init(dbHandle: dbHandle)
        case (let resultCode, _):
            throw SQLiteError(resultCode: resultCode, connection: dbHandle.map(Connection.init))
        }
    }

    let dbHandle: OpaquePointer
    init(dbHandle: OpaquePointer) {
        self.dbHandle = dbHandle
    }

    deinit {
        sqlite3_close(dbHandle)
    }

    public func prepare(sql: String) throws -> Statement {
        var stmt: OpaquePointer?
        let result = sqlite3_prepare_v2(dbHandle, sql, -1, &stmt, nil)

        if result == SQLITE_OK, let stmt = stmt {
            return Statement(connection: self, raw: stmt)
        } else {
            throw SQLiteError(resultCode: result, connection: self)
        }
    }
}
