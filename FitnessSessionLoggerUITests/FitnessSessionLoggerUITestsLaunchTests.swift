//
//  FitnessSessionLoggerUITestsLaunchTests.swift
//  FitnessSessionLoggerUITests
//
//  Created by Анастасия on 29.05.2026.
//

import XCTest

final class FitnessSessionLoggerUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
