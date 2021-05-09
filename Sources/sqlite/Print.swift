import Foundation

struct DisplayColumn {
    let name: String
    var width: Int

    init(name: String) {
        self.name = name
        self.width = name.count
    }

    var values: [String] = []

    mutating func append(_ value: String) {
        width = max(width, value.count)
        values.append(value)
    }
}

struct DisplayRow {
    var values: [String] = []

    mutating func append(_ value: String) {
        values.append(value)
    }
}

func transpose(_ columns: [DisplayColumn]) -> [DisplayRow] {
    guard let rowsCount = columns.first?.values.count, rowsCount > 0 else {
        return []
    }

    var rows = Array(repeating: DisplayRow(), count: rowsCount)

    for column in columns {
        for (index, value) in column.values.enumerated() {
            rows[index].append(value)
        }
    }

    return rows
}

func render(values: [String], widths: [Int]) -> String {
    var line = "|"

    for (value, width) in zip(values, widths) {
        line.append(" \(value.padding(toLength: width, withPad: " ", startingAt: 0)) |")
    }

    return line
}

extension Rows: CustomStringConvertible {
    func displayColumns() -> [DisplayColumn] {
        let count = columnsCount
        let names = columnNames

        var table: [DisplayColumn] = []

        for name in names {
            let column = DisplayColumn(name: name)
            table.append(column)
        }

        for row in self {
            for index in 0 ..< count {
                table[index].append(try! row.get(index, type: Optional<String>.self) ?? "NULL")
            }
        }

        return table
    }

    func displayLines() -> [String] {
        let columns = displayColumns()
        let rows = transpose(columns)

        var lines: [String] = []
        lines.reserveCapacity((rows.count + 1) * 3)

        var border = "+"
        for column in columns {
            border.append(String(repeating: "-", count: column.width + 2))
            border.append("+")
        }
        lines.append(border)

        let widths = columns.map(\.width)
        lines.append(render(values: columns.map(\.name), widths: widths))
        lines.append(border.replacingOccurrences(of: "-", with: "="))

        for row in rows {
            lines.append(render(values: row.values, widths: widths))
            lines.append(border)
        }

        return lines
    }

    public var description: String {
        displayLines().joined(separator: "\n")
    }
}
