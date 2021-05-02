import XCTest
import Nimble

import sqlite

final class sqliteTests: XCTestCase {
    var connection: Connection!

    override func setUpWithError() throws {
        connection = try Connection.open(URL(string: ":memory:")!).get()

        try connection.prepare(sql: """
        CREATE TABLE users (
            id BLOB PRIMARY KEY,
            name TEXT NOT NULL,
            username TEXT,
            age INT,
            sex TEXT NOT NULL
        )
        """).get().execute()
    }

    func testTableExists() throws {
        let statement = try connection.prepare(sql: "PRAGMA table_info(users)").get()
        let rows = Array(try statement.query().get())

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

    func testUUIDConversion() throws {
        let uuid = UUID(uuidString: "96253EE6-029E-4C14-B8C7-C7FC8209DCC0")!

        try connection.prepare(sql: "INSERT INTO users (id, name, sex) VALUES (?, ?, ?)").get()
            .execute(params: [uuid, "Vladimir Burdukov", "male"])

        let statement = try connection.prepare(sql: "SELECT id, name FROM users").get()
        let rows = Array(try statement.query().get())

        expect(rows).to(haveCount(1))
        expect(try rows[0].get(0, type: UUID.self)) == uuid
        expect(try rows[0].get(1, type: String.self)) == "Vladimir Burdukov"
    }

    func testRawRepresentableConversion() throws {
        enum Sex: String, FromSQL, ToSQL {
            case male, female
        }

        let uuid = UUID(uuidString: "96253EE6-029E-4C14-B8C7-C7FC8209DCC0")!

        try connection.prepare(sql: "INSERT INTO users (id, name, sex) VALUES (?, ?, ?)").get()
            .execute(params: [uuid, "Vladimir Burdukov", Sex.male])

        let statement = try connection.prepare(sql: "SELECT sex FROM users").get()
        let rows = Array(try statement.query().get())

        expect(rows).to(haveCount(1))
        expect(try rows[0].get(0, type: Sex.self)) == .male
    }
}
