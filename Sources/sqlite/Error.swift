import Foundation
import SQLite3

public enum SQLiteError: Swift.Error {
    case sqlite(Code, message: String, description: String?)
    case noSuchColumn(Int)

    init(code: Code, connection: Connection?) {
        let message = String(cString: sqlite3_errstr(code.resultCode))
        let description = connection.map { String(cString: sqlite3_errmsg($0.dbHandle)) }

        self = .sqlite(code, message: message, description: description)
    }

    init(resultCode: Int32, connection: Connection?) {
        self.init(code: Code(resultCode: resultCode), connection: connection)
    }
}

extension SQLiteError {
    public enum Code {
        /// Internal logic error in SQLite
        case internalMalfunction
        /// Access permission denied
        case permissionDenied
        /// Callback routine requested an abort
        case operationAborted
        /// The database file is locked
        case databaseBusy
        /// A table in the database is locked
        case databaseLocked
        /// A malloc() failed
        case outOfMemory
        /// Attempt to write a readonly database
        case readOnly
        /// Operation terminated by sqlite3_interrupt()
        case operationInterrupted
        /// Some kind of disk I/O error occurred
        case systemIOFailure
        /// The database disk image is malformed
        case databaseCorrupt
        /// Unknown opcode in sqlite3_file_control()
        case notFound
        /// Insertion failed because database is full
        case diskFull
        /// Unable to open the database file
        case cannotOpen
        /// Database lock protocol error
        case fileLockingProtocolFailed
        /// The database schema changed
        case schemaChanged
        /// String or BLOB exceeds size limit
        case tooBig
        /// Abort due to constraint violation
        case constraintViolation
        /// Data type mismatch
        case typeMismatch
        /// Library used incorrectly
        case apiMisuse
        /// Uses OS features not supported on host
        case noLargeFileSupport
        /// Authorization denied
        case authorizationForStatementDenied
        /// 2nd parameter to sqlite3_bind out of range
        case parameterOutOfRange
        /// File opened that is not a database file
        case notADatabase
        /// SQL error or missing database
        case unknown

        init(resultCode: Int32) {
            switch resultCode & 0xff {
            case SQLITE_INTERNAL: self = .internalMalfunction
            case SQLITE_PERM: self = .permissionDenied
            case SQLITE_ABORT: self = .operationAborted
            case SQLITE_BUSY: self = .databaseBusy
            case SQLITE_LOCKED: self = .databaseLocked
            case SQLITE_NOMEM: self = .outOfMemory
            case SQLITE_READONLY: self = .readOnly
            case SQLITE_INTERRUPT: self = .operationInterrupted
            case SQLITE_IOERR: self = .systemIOFailure
            case SQLITE_CORRUPT: self = .databaseCorrupt
            case SQLITE_NOTFOUND: self = .notFound
            case SQLITE_FULL: self = .diskFull
            case SQLITE_CANTOPEN: self = .cannotOpen
            case SQLITE_PROTOCOL: self = .fileLockingProtocolFailed
            case SQLITE_SCHEMA: self = .schemaChanged
            case SQLITE_TOOBIG: self = .tooBig
            case SQLITE_CONSTRAINT: self = .constraintViolation
            case SQLITE_MISMATCH: self = .typeMismatch
            case SQLITE_MISUSE: self = .apiMisuse
            case SQLITE_NOLFS: self = .noLargeFileSupport
            case SQLITE_AUTH: self = .authorizationForStatementDenied
            case SQLITE_RANGE: self = .parameterOutOfRange
            case SQLITE_NOTADB: self = .notADatabase
            default: self = .unknown
            }
        }

        var resultCode: Int32 {
            switch self {
            case .internalMalfunction: return SQLITE_INTERNAL
            case .permissionDenied: return SQLITE_PERM
            case .operationAborted: return SQLITE_ABORT
            case .databaseBusy: return SQLITE_BUSY
            case .databaseLocked: return SQLITE_LOCKED
            case .outOfMemory: return SQLITE_NOMEM
            case .readOnly: return SQLITE_READONLY
            case .operationInterrupted: return SQLITE_INTERRUPT
            case .systemIOFailure: return SQLITE_IOERR
            case .databaseCorrupt: return SQLITE_CORRUPT
            case .notFound: return SQLITE_NOTFOUND
            case .diskFull: return SQLITE_FULL
            case .cannotOpen: return SQLITE_CANTOPEN
            case .fileLockingProtocolFailed: return SQLITE_PROTOCOL
            case .schemaChanged: return SQLITE_SCHEMA
            case .tooBig: return SQLITE_TOOBIG
            case .constraintViolation: return SQLITE_CONSTRAINT
            case .typeMismatch: return SQLITE_MISMATCH
            case .apiMisuse: return SQLITE_MISUSE
            case .noLargeFileSupport: return SQLITE_NOLFS
            case .authorizationForStatementDenied: return SQLITE_AUTH
            case .parameterOutOfRange: return SQLITE_RANGE
            case .notADatabase: return SQLITE_NOTADB
            case .unknown: return SQLITE_ERROR
            }
        }
    }

}
