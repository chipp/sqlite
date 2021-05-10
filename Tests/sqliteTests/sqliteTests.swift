import XCTest
import Nimble
import Difference

@testable import sqlite

final class sqliteTests: XCTestCase {
    var connection: Connection!

    override func setUpWithError() throws {
        connection = try Connection(URL(string: ":memory:")!)

        try connection.prepare(sql: """
        CREATE TABLE users (
            id BLOB PRIMARY KEY,
            name TEXT NOT NULL,
            username TEXT,
            age INT,
            sex TEXT NOT NULL
        )
        """).execute()
    }

    override func tearDown() {
        connection = nil
    }

    func testTableExists() throws {
        let statement = try connection.prepare(sql: "PRAGMA table_info(users)")
        let rows = Array(try statement.query())

        expect(rows).to(haveCount(5))

        expect(try rows[0].get(1, type: String.self)) == "id"
        expect(try rows[0].get(2, type: String.self)) == "BLOB"
        expect(try rows[0].get(3, type: Bool.self)).to(beFalse())
        expect(try rows[0].get(5, type: Int.self)) == 1

        expect(try rows[1].get(1, type: String.self)) == "name"
        expect(try rows[1].get(2, type: String.self)) == "TEXT"
        expect(try rows[1].get(3, type: Bool.self)).to(beTrue())
        expect(try rows[1].get(5, type: Int.self)) == 0

        expect(try rows[2].get(1, type: String.self)) == "username"
        expect(try rows[2].get(2, type: String.self)) == "TEXT"
        expect(try rows[2].get(3, type: Bool.self)).to(beFalse())
        expect(try rows[2].get(5, type: Int.self)) == 0

        expect(try rows[3].get(1, type: String.self)) == "age"
        expect(try rows[3].get(2, type: String.self)) == "INT"
        expect(try rows[3].get(3, type: Bool.self)).to(beFalse())
        expect(try rows[3].get(5, type: Int.self)) == 0

        expect(try rows[4].get(1, type: String.self)) == "sex"
        expect(try rows[4].get(2, type: String.self)) == "TEXT"
        expect(try rows[4].get(3, type: Bool.self)).to(beTrue())
        expect(try rows[4].get(5, type: Int.self)) == 0
    }

    func testColumnsCountAndNames() throws {
        let statement = try connection.prepare(sql: "SELECT * FROM users")
        let rows = try statement.query()

        expect(rows.columnsCount) == 5
        expect(rows.columnNames) == ["id", "name", "username", "age", "sex"]
    }

    func testUUIDConversion() throws {
        let uuid = UUID(uuidString: "96253EE6-029E-4C14-B8C7-C7FC8209DCC0")!

        try connection.prepare(sql: "INSERT INTO users (id, name, sex) VALUES (?, ?, ?)")
            .execute(params: [uuid, "Vladimir Burdukov", "male"])

        let statement = try connection.prepare(sql: "SELECT id, name FROM users")
        let rows = Array(try statement.query())

        expect(rows).to(haveCount(1))
        expect(try rows[0].get(0, type: UUID.self)) == uuid
        expect(try rows[0].get(1, type: String.self)) == "Vladimir Burdukov"
    }

    func testRawRepresentableConversion() throws {
        enum Sex: String, FromSQL, ToSQL {
            case male, female
        }

        let uuid = UUID(uuidString: "96253EE6-029E-4C14-B8C7-C7FC8209DCC0")!

        try connection.prepare(sql: "INSERT INTO users (id, name, sex) VALUES (?, ?, ?)")
            .execute(params: [uuid, "Vladimir Burdukov", Sex.male])

        let statement = try connection.prepare(sql: "SELECT sex FROM users")
        let rows = Array(try statement.query())

        expect(rows).to(haveCount(1))
        expect(try rows[0].get(0, type: Sex.self)) == .male
    }

    func testStatementTable() throws {
        let insert = try connection.prepare(sql: "INSERT INTO users (id, name, sex) VALUES (?, ?, ?)")

        try insert.execute(params: [Data([49]), "Vladimir Burdukov", "male"])
        try insert.execute(params: [Data([50]), "Anna Burdukova", "female"])
        try insert.execute(params: [Data([51]), "Vera Burdukova", "female"])

        let select = try connection.prepare(sql: "SELECT * FROM users")
        let rows = try select.query()
        let columns = rows.displayColumns()

        expect(columns.map(\.name)) == ["id", "name", "username", "age", "sex"]
        expect(columns.map(\.width)) == [2, 17, 8, 4, 6]
        expect(columns.map(\.values)) == [
            ["1", "2", "3"],
            ["Vladimir Burdukov", "Anna Burdukova", "Vera Burdukova"],
            ["NULL", "NULL", "NULL"],
            ["NULL", "NULL", "NULL"],
            ["male", "female", "female"]
        ]

        select.reset()

        expect(rows.displayLines()).to(equalDiff([
            "+----+-------------------+----------+------+--------+",
            "| id | name              | username | age  | sex    |",
            "+====+===================+==========+======+========+",
            "| 1  | Vladimir Burdukov | NULL     | NULL | male   |",
            "+----+-------------------+----------+------+--------+",
            "| 2  | Anna Burdukova    | NULL     | NULL | female |",
            "+----+-------------------+----------+------+--------+",
            "| 3  | Vera Burdukova    | NULL     | NULL | female |",
            "+----+-------------------+----------+------+--------+"
        ]))
    }

    func testSQLiteValueDecoding() throws {
        try connection.prepare(sql: """
        CREATE TABLE types (
            id INT PRIMARY KEY,
            height REAL NOT NULL,
            username TEXT,
            blob BLOB
        )
        """).execute()

        let insert = try connection.prepare(sql: "INSERT INTO types (id, height, username, blob) VALUES (?, ?, ?, ?)")
        try insert.execute(params: [1, 1.2, "chipp", Data([1])])
        try insert.execute(params: [2, 2.2, Optional<String>.none, Optional<Data>.none])

        let rows = Array(try connection.prepare(sql: "SELECT * FROM types").query())

        expect(try rows[0].getValue(0)) == .int(1)
        expect(try rows[0].getValue(1)) == .real(1.2)
        expect(try rows[0].getValue(2)) == .text("chipp")
        expect(try rows[0].getValue(3)) == .blob(Data([1]))

        expect(try rows[1].getValue(0)) == .int(2)
        expect(try rows[1].getValue(1)) == .real(2.2)
        expect(try rows[1].getValue(2)) == .null
        expect(try rows[1].getValue(3)) == .null
    }
}

public func equalDiff<T: Equatable>(_ expectedValue: T?) -> Predicate<T> {
    return Predicate.define { actualExpression in
        let receivedValue = try actualExpression.evaluate()

        if receivedValue == nil {
            var message = ExpectationMessage.fail("")
            if let expectedValue = expectedValue {
                message = ExpectationMessage.expectedCustomValueTo("equal <\(expectedValue)>", actual: "nil")
            }
            return PredicateResult(status: .fail, message: message)
        }
        if expectedValue == nil {
            return PredicateResult(status: .fail, message: ExpectationMessage.fail("").appendedBeNilHint())
        }

        return PredicateResult(bool: receivedValue == expectedValue, message: ExpectationMessage.fail("Found difference for " + diff(expectedValue, receivedValue).joined(separator: ", ")))
    }
}
