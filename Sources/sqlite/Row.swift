import Foundation
import SQLite3

public struct Rows: Sequence {
    let statement: Statement

    public var columnsCount: Int {
        Int(sqlite3_column_count(statement.raw))
    }

    public var columnNames: [String] {
        var names: [String] = []
        names.reserveCapacity(columnsCount)

        for index in 0 ..< columnsCount {
            let name = String(cString: sqlite3_column_name(statement.raw, Int32(index)))
            names.append(name)
        }

        return names
    }

    public func makeIterator() -> RowsIterator {
        RowsIterator(statement: statement)
    }
}

public struct RowsIterator: IteratorProtocol {
    let statement: Statement

    public typealias Element = Row

    public func next() -> Element? {
        guard let success = try? statement.step() else {
            return nil
        }

        return success ? Row(statement: statement) : nil
    }
}

public final class Row {
    let values: [OpaquePointer]
    init(statement: Statement) {
        var values: [OpaquePointer] = []

        let count = Int(sqlite3_column_count(statement.raw))
        values.reserveCapacity(count)

        for index in 0 ..< count {
            var value = statement.value(at: index)
            value = sqlite3_value_dup(value)
            values.append(value)
        }

        self.values = values
    }

    deinit {
        values.forEach(sqlite3_value_free)
    }

    public func get<T: FromSQL>(_ column: Int) throws -> T {
        guard values.indices.contains(column) else {
            throw SQLiteError.noSuchColumn(column)
        }

        return T.decode(from: values[column])
    }

    public func get<T: FromSQL>(_ column: Int, type: T.Type) throws -> T {
        guard values.indices.contains(column) else {
            throw SQLiteError.noSuchColumn(column)
        }

        return T.decode(from: values[column])
    }
}
