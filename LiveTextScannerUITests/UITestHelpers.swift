//
//  UITestHelpers.swift
//  LiveTextScannerUITests
//
//  Created by Malky on 30/06/2026.
//

import XCTest

extension XCUIApplication {
    /// Configures and returns an app instance ready for UI testing.
    /// `--uitesting` disables real camera/storage; `--seed-history` pre-populates the history store.
    static func uitestingApp(seedHistory: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        var args = ["--uitesting"]
        if seedHistory { args.append("--seed-history") }
        app.launchArguments = args
        return app
    }

    /// Waits up to `timeout` seconds for `element` to exist, then returns it.
    @discardableResult
    func waitFor(_ element: XCUIElement, timeout: TimeInterval = 3) -> XCUIElement {
        _ = element.waitForExistence(timeout: timeout)
        return element
    }
}
