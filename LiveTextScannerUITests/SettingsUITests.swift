//
//  SettingsUITests.swift
//  LiveTextScannerUITests
//
//  Created by Malky on 30/06/2026.
//

import XCTest

final class SettingsUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = .uitestingApp()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Navigation lifecycle

    func testSettingsScreenIsReachable() {
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Language Settings"].waitForExistence(timeout: 3))
    }

    func testBackNavigationReturnsToCameraScreen() {
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Language Settings"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertFalse(app.navigationBars["Language Settings"].waitForExistence(timeout: 2))
    }

    // MARK: - Auto-detect toggle

    func testAutoDetectToggleIsOnByDefault() {
        app.buttons["Settings"].tap()
        let toggle = app.switches["Auto-detect language"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertEqual(toggle.value as? String, "1")
    }

    func testDisablingAutoDetectShowsLanguageSection() {
        app.buttons["Settings"].tap()
        let toggle = app.switches["Auto-detect language"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        tapSwitchKnob(toggle)
        let header = activeLanguagesHeader
        XCTAssertTrue(header.waitForExistence(timeout: 3))
    }

    func testReenablingAutoDetectHidesLanguageSection() {
        app.buttons["Settings"].tap()
        let toggle = app.switches["Auto-detect language"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        tapSwitchKnob(toggle) // off
        let header = activeLanguagesHeader
        XCTAssertTrue(header.waitForExistence(timeout: 3))
        tapSwitchKnob(toggle) // back on
        // Poll briefly — the section animates out, so existence may linger one frame.
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: header)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 3), .completed)
    }

    /// SwiftUI Form section headers expose their text via the accessibility tree as
    /// static text — case-insensitive match handles iOS uppercasing the visible label.
    private var activeLanguagesHeader: XCUIElement {
        let predicate = NSPredicate(format: "label ==[c] %@", "Active Languages")
        return app.staticTexts.matching(predicate).firstMatch
    }

    /// A plain `.tap()` on a SwiftUI Toggle inside a Form lands on the label, not the knob,
    /// so the switch's value doesn't change. Tapping the trailing edge hits the actual UISwitch.
    private func tapSwitchKnob(_ toggle: XCUIElement) {
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
    }
}
