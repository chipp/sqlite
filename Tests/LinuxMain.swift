import XCTest

import sqliteTests

var tests = [XCTestCaseEntry]()
tests += sqliteTests.allTests()
XCTMain(tests)
