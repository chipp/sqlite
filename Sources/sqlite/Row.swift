import Foundation
import SQLite3

public typealias Rows = IteratorSequence<RowsIterator>

public struct RowsIterator: IteratorProtocol {
    let statement: Statement

    public typealias Element = Row

    public func next() -> Element? {
        if case .success(true) = statement.step() {
            return Row(statement: statement)
        } else {
            return nil
        }
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
