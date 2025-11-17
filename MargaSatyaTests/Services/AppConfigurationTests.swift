//
//  AppConfigurationTests.swift
//  MargaSatyaTests
//
//  Unit tests for AppConfiguration
//

import Testing
import Foundation
@testable import MargaSatya

struct AppConfigurationTests {
    // MARK: - API Configuration Tests

    @Test("API base URL is properly configured")
    func testAPIBaseURL() {
        let baseURL = AppConfiguration.API.baseURL
        #expect(baseURL.isEmpty == false)
        #expect(baseURL.hasPrefix("https://"))
    }

    @Test("API timeout has reasonable value")
    func testAPITimeout() {
        let timeout = AppConfiguration.API.timeout
        #expect(timeout > 0)
        #expect(timeout <= 60) // Should not exceed 60 seconds
    }

    @Test("API endpoints are properly defined")
    func testAPIEndpoints() {
        let endpoint = AppConfiguration.API.Endpoints.resolveExamCode
        #expect(endpoint.isEmpty == false)
        #expect(endpoint.hasPrefix("/"))
    }

    // MARK: - Assessment Configuration Tests

    @Test("Default admin PIN is configured")
    func testDefaultAdminPIN() {
        let pin = AppConfiguration.Assessment.defaultAdminPIN
        #expect(pin.isEmpty == false)
        #expect(pin.count >= 4) // PIN should be at least 4 characters
    }

    @Test("Triple tap window has reasonable value")
    func testTripleTapWindow() {
        let window = AppConfiguration.Assessment.tripleTapWindow
        #expect(window > 0)
        #expect(window <= 5.0) // Should not exceed 5 seconds
    }

    // MARK: - WebView Configuration Tests

    @Test("Allowed domains are configured")
    func testAllowedDomains() {
        let domains = AppConfiguration.WebView.allowedDomains
        #expect(domains.isEmpty == false)
        #expect(domains.contains("docs.google.com"))
    }

    @Test("Blocked schemes are configured")
    func testBlockedSchemes() {
        let schemes = AppConfiguration.WebView.blockedSchemes
        #expect(schemes.isEmpty == false)
        #expect(schemes.contains("mailto"))
        #expect(schemes.contains("tel"))
    }

    // MARK: - UI Configuration Tests

    @Test("Minimum exam code length is reasonable")
    func testMinExamCodeLength() {
        let minLength = AppConfiguration.UI.minExamCodeLength
        #expect(minLength > 0)
        #expect(minLength <= 10) // Should not be too long
    }

    @Test("Transition duration is reasonable")
    func testTransitionDuration() {
        let duration = AppConfiguration.UI.transitionDuration
        #expect(duration > 0)
        #expect(duration <= 1.0) // Should not exceed 1 second
    }

    @Test("Timer update interval is reasonable")
    func testTimerUpdateInterval() {
        let interval = AppConfiguration.UI.timerUpdateInterval
        #expect(interval > 0)
        #expect(interval <= 5.0) // Should update frequently
    }

    @Test("Timer warning threshold is configured")
    func testTimerWarningThreshold() {
        let threshold = AppConfiguration.UI.timerWarningThreshold
        #expect(threshold > 0)
        #expect(threshold <= 600) // Should not exceed 10 minutes
    }

    // MARK: - App Info Tests

    @Test("App version is configured")
    func testAppVersion() {
        let version = AppConfiguration.Info.version
        #expect(version.isEmpty == false)
    }

    @Test("App name is configured")
    func testAppName() {
        let name = AppConfiguration.Info.name
        #expect(name.isEmpty == false)
        #expect(name == "MargaSatya")
    }

    @Test("App tagline is configured")
    func testAppTagline() {
        let tagline = AppConfiguration.Info.tagline
        #expect(tagline.isEmpty == false)
    }

    // MARK: - Feature Flags Tests

    @Test("Development mode flag exists")
    func testDevelopmentModeFlag() {
        let isDev = AppConfiguration.Features.isDevelopmentMode
        // Should be a boolean value (true or false)
        #expect(isDev == true || isDev == false)
    }

    @Test("Admin override flag exists")
    func testAdminOverrideFlag() {
        let isEnabled = AppConfiguration.Features.adminOverrideEnabled
        #expect(isEnabled == true || isEnabled == false)
    }

    @Test("Haptic feedback flag exists")
    func testHapticFeedbackFlag() {
        let isEnabled = AppConfiguration.Features.hapticFeedbackEnabled
        #expect(isEnabled == true || isEnabled == false)
    }
}
