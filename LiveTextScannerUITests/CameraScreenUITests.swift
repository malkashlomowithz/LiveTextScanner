//
//  CameraScreenUITests.swift
//  LiveTextScannerUITests
//
//  Created by Malky on 30/06/2026.
//

import XCTest

final class CameraScreenUITests: XCTestCase {

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

    // MARK: - Controls presence

    func testShutterButtonIsVisible() {
        XCTAssertTrue(app.buttons["Capture text"].waitForExistence(timeout: 3))
    }

    func testSettingsButtonIsVisible() {
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 3))
    }

    func testHistoryButtonIsVisible() {
        XCTAssertTrue(app.buttons["History"].waitForExistence(timeout: 3))
    }

    // MARK: - Shutter button state

    func testShutterButtonIsDisabledWhenNoTextDetected() {
        // MockTextRecognizer returns no regions by default, so the button must stay disabled.
        let shutter = app.buttons["Capture text"]
        XCTAssertTrue(shutter.waitForExistence(timeout: 3))
        XCTAssertFalse(shutter.isEnabled)
    }
}
