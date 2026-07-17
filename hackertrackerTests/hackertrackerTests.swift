//
//  hackertrackerTests.swift
//  hackertrackerTests
//
//  Created by Seth W Law on 5/2/22.
//

@testable import hackertracker
import XCTest

class hackertrackerTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testContentDecodesVisibleAgeMin() throws {
        let json = """
        {"id": 1, "description": "d", "links": [], "media": [], "people": [],
         "sessions": [], "tag_ids": [], "title": "t", "visible_age_min": 18}
        """.data(using: .utf8)!
        let content = try JSONDecoder().decode(Content.self, from: json)
        XCTAssertEqual(content.visibleAgeMin, 18)
    }

    func testContentDefaultsVisibleAgeMinToNilWhenAbsent() throws {
        let json = """
        {"id": 2, "description": "d", "links": [], "media": [], "people": [],
         "sessions": [], "tag_ids": [], "title": "t"}
        """.data(using: .utf8)!
        let content = try JSONDecoder().decode(Content.self, from: json)
        XCTAssertNil(content.visibleAgeMin)
    }

    func testOrganizationDecodesVisibleAgeMin() throws {
        let json = """
        {"name": "n", "description": "d", "links": [], "media": [],
         "tag_ids": [], "visible_age_min": 21}
        """.data(using: .utf8)!
        let org = try JSONDecoder().decode(Organization.self, from: json)
        XCTAssertEqual(org.visibleAgeMin, 21)
    }
}
