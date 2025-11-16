//
//  AppConfiguration.swift
//  MargaSatya
//
//  Application configuration management
//

import Foundation

/// Application configuration
struct AppConfiguration {
    /// API Configuration
    struct API {
        /// Base URL for API endpoints
        static let baseURL = "https://api.margasatya.com"

        /// API timeout in seconds
        static let timeout: TimeInterval = 30

        /// Endpoints
        struct Endpoints {
            static let resolveExamCode = "/exam/resolve-code"
        }
    }

    /// Assessment Configuration
    struct Assessment {
        /// Default admin PIN for emergency override
        static let defaultAdminPIN = "1234"

        /// Triple tap detection window (seconds)
        static let tripleTapWindow: TimeInterval = 2.0
    }

    /// WebView Configuration
    struct WebView {
        /// Allowed domains for exam content
        static let allowedDomains = [
            "docs.google.com",
            "accounts.google.com",
            "forms.google.com"
        ]

        /// Blocked URL schemes
        static let blockedSchemes = [
            "mailto",
            "tel",
            "sms",
            "facetime",
            "itms-apps"
        ]
    }

    /// UI Configuration
    struct UI {
        /// Minimum exam code length
        static let minExamCodeLength = 3

        /// Animation duration for transitions
        static let transitionDuration: TimeInterval = 0.3

        /// Timer update interval (seconds)
        static let timerUpdateInterval: TimeInterval = 1.0

        /// Warning threshold for timer (seconds)
        static let timerWarningThreshold = 300 // 5 minutes
    }

    /// App Information
    struct Info {
        static let version = "1.0"
        static let name = "MargaSatya"
        static let tagline = "Secure Exam Browser"
    }

    /// Feature Flags
    struct Features {
        /// Enable development mode (uses mock API)
        static var isDevelopmentMode = true

        /// Enable admin override
        static let adminOverrideEnabled = true

        /// Enable haptic feedback
        static let hapticFeedbackEnabled = true
    }
}
