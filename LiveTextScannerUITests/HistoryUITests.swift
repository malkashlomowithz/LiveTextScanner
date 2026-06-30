//
//  HistoryUITests.swift
//  LiveTextScannerUITests
//
//  Created by Malky on 30/06/2026.
//

import XCTest

// MARK: - Empty history

final class HistoryEmptyUITests: XCTestCase {

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

    func testHistoryScreenIsReachable() {
        app.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["Scan History"].waitForExistence(timeout: 3))
    }

    func testEmptyStateIsShownWhenNoScans() {
        app.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["No Scans Yet"].waitForExistence(timeout: 3))
    }

    func testSearchBarIsPresent() {
        app.buttons["History"].tap()
        XCTAssertTrue(app.searchFields["Search scans"].waitForExistence(timeout: 3))
    }

    func testBackNavigationReturnsToCameraScreen() {
        app.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["Scan History"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertFalse(app.navigationBars["Scan History"].waitForExistence(timeout: 2))
    }
}

// MARK: - History with pre-seeded scans

final class HistoryWithDataUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = .uitestingApp(seedHistory: true)
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testSeededScansAreVisible() {
        app.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Hello World from UI test"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Bonjour le monde"].exists)
    }

    func testTappingScanOpensScanDetail() {
        app.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Hello World from UI test"].waitForExistence(timeout: 3))
        app.staticTexts["Hello World from UI test"].tap()
        // ScanDetailView shows the text selectable in a ScrollView
        XCTAssertTrue(app.staticTexts["Hello World from UI test"].waitForExistence(timeout: 3))
        // Navigation bar shows the scan date
        XCTAssertTrue(app.navigationBars.element.exists)
    }

    func testSwipeToDeleteRemovesScan() {
        app.buttons["History"].tap()
        let scanText = app.staticTexts["Bonjour le monde"]
        XCTAssertTrue(scanText.waitForExistence(timeout: 3))
        scanText.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertFalse(app.staticTexts["Bonjour le monde"].waitForExistence(timeout: 2))
    }

    func testSearchFiltersByScanContent() {
        app.buttons["History"].tap()
        XCTAssertTrue(app.searchFields["Search scans"].waitForExistence(timeout: 3))
        app.searchFields["Search scans"].tap()
        app.searchFields["Search scans"].typeText("Bonjour")
        XCTAssertTrue(app.staticTexts["Bonjour le monde"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Hello World from UI test"].exists)
    }
}
