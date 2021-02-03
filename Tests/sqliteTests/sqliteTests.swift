import XCTest
import Nimble

@testable import sqlite

final class sqliteTests: XCTestCase {
    var connection: Connection!

    override func setUpWithError() throws {
        connection = try Connection.open(URL(string: ":memory:")!)

        try connection.prepare(sql: """
        CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            username TEXT,
            age INT NOT NULL
        )
        """).get().execute()
    }

    func testTableExists() throws {
        let statement = try connection.prepare(sql: "PRAGMA table_info(users)").get()
        let rows = Array(try statement.query().get())

        expect(rows).to(haveCount(4))

        expect(try rows[0].get(1, type: String.self)) == "id"
        expect(try rows[0].get(2, type: String.self)) == "INTEGER"
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
        expect(try rows[3].get(3, type: Bool.self)).to(beTrue())
        expect(try rows[3].get(5, type: Int.self)) == 0
    }
}
