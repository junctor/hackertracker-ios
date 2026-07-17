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

    // Organization is not decode-tested here: its @DocumentID id cannot be decoded by a plain JSONDecoder. The visible_age_min CodingKey wiring is identical to Content's, which IS covered above.
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
}

@MainActor
final class AgeGateTests: XCTestCase {
    /// Feeds a fixed range so the decision logic can be tested without the OS.
    struct FakeProvider: AgeRangeProviding {
        let result: AgeRangeResult
        func requestRange(gates: [Int], forcePrompt: Bool) async -> AgeRangeResult { result }
    }

    private func gate(lower: Int?, upper: Int?) async -> AgeGate {
        let g = AgeGate(provider: FakeProvider(result: .init(lowerBound: lower, upperBound: upper)))
        await g.refresh(forcePrompt: false)
        return g
    }

    func testNilMinIsAlwaysVisible() async {
        let g = await gate(lower: 13, upper: 15)   // confirmed under 18
        XCTAssertTrue(g.isVisible(minAge: nil))     // no minimum → visible
    }

    func testConfirmedUnderIsHidden() async {
        let g = await gate(lower: 13, upper: 15)
        XCTAssertFalse(g.isVisible(minAge: 18))     // max age 15 < 18 → hidden
    }

    func testEqualBoundaryIsVisible() async {
        let g = await gate(lower: 16, upper: 16)   // upperBound == minAge
        XCTAssertTrue(g.isVisible(minAge: 16))     // 16 >= 16 → visible
    }

    func testAboveMinWithKnownUpperIsVisible() async {
        let g = await gate(lower: 16, upper: 17)
        XCTAssertTrue(g.isVisible(minAge: 13))     // 17 >= 13 → visible (known upper)
    }

    func testStraddleFailsOpen() async {
        let g = await gate(lower: 16, upper: 17)
        XCTAssertTrue(g.isVisible(minAge: 16))      // 17 >= 16 → visible
        XCTAssertFalse(g.isVisible(minAge: 18))     // 17 < 18 → hidden
    }

    func testUnknownRangeFailsOpen() async {
        let g = await gate(lower: nil, upper: nil)  // declined/error/pre-26
        XCTAssertTrue(g.isVisible(minAge: 18))      // no signal → visible
    }
}
