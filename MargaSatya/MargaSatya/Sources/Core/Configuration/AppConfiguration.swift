//
//  AppConfiguration.swift
//  MargaSatya
//
//  Application configuration management
//

import Foundation

/// Application configuration
struct AppConfiguration {

    // MARK: - Firebase Configuration

    /// Firebase / Firestore Configuration
    struct Firebase {
        /// Use Firestore emulator for development
        static var useEmulator = false

        /// Emulator host
        static let emulatorHost = "localhost"

        /// Emulator port
        static let emulatorPort = 8080

        /// Firestore collection names
        struct Collections {
            static let users = "users"
            static let students = "students"
            static let exams = "exams"
            static let examSessions = "examSessions"
            static let appConfigs = "appConfigs"
        }

        /// Firestore subcollection names
        struct Subcollections {
            static let questions = "questions"
            static let participants = "participants"
            static let answers = "answers"
        }
    }

    // MARK: - Authentication Configuration

    /// Authentication Configuration
    struct Auth {
        /// Minimum password length
        static let minPasswordLength = 8

        /// Password must contain number
        static let requireNumber = true

        /// Password must contain uppercase
        static let requireUppercase = false

        /// Admin registration key (untuk keamanan)
        static let adminRegistrationKey = "ADMIN-SECURE-2024"

        /// Session timeout (hours)
        static let sessionTimeout: TimeInterval = 24 * 3600
    }

    // MARK: - Encryption Configuration

    /// Encryption Configuration
    struct Encryption {
        /// Algorithm used (display only, actual is in service)
        static let algorithm = "AES-256-GCM"

        /// Key version (for future key rotation)
        static let currentKeyVersion = 1

        /// Keychain service identifier
        static let keychainService = "com.margasatya.secureexamid.encryption"
    }

    // MARK: - Assessment Configuration

    /// Assessment / AAC Configuration
    struct Assessment {
        /// Default admin PIN for emergency override
        static let defaultAdminPIN = "1234"

        /// Triple tap detection window (seconds)
        static let tripleTapWindow: TimeInterval = 2.0

        /// Auto-save interval for answers (seconds)
        static let autoSaveInterval: TimeInterval = 10.0

        /// Maximum retry attempts for submission
        static let maxSubmissionRetries = 5

        /// Submission retry delay (seconds)
        static let submissionRetryDelay: TimeInterval = 2.0
    }

    // MARK: - WebView Configuration

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

        /// WebView timeout (seconds)
        static let loadTimeout: TimeInterval = 30
    }

    // MARK: - UI Configuration

    /// UI Configuration
    struct UI {
        /// Minimum exam code length
        static let minExamCodeLength = 4

        /// Maximum exam code length
        static let maxExamCodeLength = 20

        /// Minimum NIS length
        static let minNISLength = 4

        /// Maximum NIS length
        static let maxNISLength = 20

        /// Animation duration for transitions
        static let transitionDuration: TimeInterval = 0.3

        /// Timer update interval (seconds)
        static let timerUpdateInterval: TimeInterval = 1.0

        /// Warning threshold for timer (seconds)
        static let timerWarningThreshold = 300 // 5 minutes

        /// Question navigation grid columns
        static let questionGridColumns = 5

        /// Debounce delay for search (seconds)
        static let searchDebounceDelay: TimeInterval = 0.5
    }

    // MARK: - Validation

    /// Validation Rules
    struct Validation {
        /// Email regex pattern
        static let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        /// NIS pattern (alphanumeric)
        static let nisPattern = "^[A-Za-z0-9]+$"

        /// Exam code pattern (alphanumeric with dash/underscore)
        static let examCodePattern = "^[A-Za-z0-9_-]+$"

        /// Name pattern (letters and spaces)
        static let namePattern = "^[A-Za-z\\s]+$"
    }

    // MARK: - App Information

    /// App Information
    struct Info {
        static let version = "2.0.0"
        static let name = "MargaSatya"
        static let tagline = "Platform Ujian Digital Aman"
        static let bundleId = "com.margasatya.secureexamid"
    }

    // MARK: - Feature Flags

    /// Feature Flags
    struct Features {
        /// Enable development mode (uses mock services)
        static var isDevelopmentMode = false

        /// Use Firebase emulator
        static var useFirebaseEmulator = false

        /// Enable admin override during exam
        static let adminOverrideEnabled = true

        /// Enable haptic feedback
        static let hapticFeedbackEnabled = true

        /// Enable offline mode (save answers locally)
        static let offlineModeEnabled = true

        /// Enable liquid glass UI effects
        static let liquidGlassEnabled = true

        /// Enable analytics tracking
        static let analyticsEnabled = false

        /// Enable debug logging
        static var debugLogging = false
    }

    // MARK: - Network Configuration

    /// Network Configuration
    struct Network {
        /// Request timeout (seconds)
        static let requestTimeout: TimeInterval = 30

        /// Maximum retry attempts
        static let maxRetries = 3

        /// Retry delay (seconds)
        static let retryDelay: TimeInterval = 1.0

        /// Retry multiplier (exponential backoff)
        static let retryMultiplier: Double = 2.0

        /// Check connection before operations
        static let checkConnectionBeforeOperation = true
    }

    // MARK: - Performance

    /// Performance Configuration
    struct Performance {
        /// Maximum questions to load at once
        static let maxQuestionsPerBatch = 50

        /// Image cache size (MB)
        static let imageCacheSizeMB = 100

        /// Enable lazy loading for questions
        static let lazyLoadingEnabled = true
    }
}
