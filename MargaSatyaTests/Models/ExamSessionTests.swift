//
//  ExamSessionTests.swift
//  MargaSatyaTests
//
//  Unit tests for ExamSession model
//

import Testing
import Foundation
@testable import MargaSatya

@MainActor
struct ExamSessionTests {
    // MARK: - Initialization Tests

    @Test("ExamSession initializes with default values")
    func testDefaultInitialization() {
        let session = ExamSession()

        #expect(session.examId.isEmpty)
        #expect(session.examUrl.isEmpty)
        #expect(session.examTitle.isEmpty)
        #expect(session.duration == 0)
        #expect(session.lockMode == false)
        #expect(session.startTime == nil)
        #expect(session.isActive == false)
        #expect(session.timeRemaining == 0)
    }

    @Test("ExamSession initializes with custom values")
    func testCustomInitialization() {
        let session = ExamSession(
            examId: "TEST001",
            examUrl: "https://test.com/exam",
            examTitle: "Test Exam",
            duration: 45,
            lockMode: true
        )

        #expect(session.examId == "TEST001")
        #expect(session.examUrl == "https://test.com/exam")
        #expect(session.examTitle == "Test Exam")
        #expect(session.duration == 45)
        #expect(session.lockMode == true)
        #expect(session.isActive == false)
    }

    @Test("ExamSession initializes from API response")
    func testInitializationFromResponse() {
        let response = ExamResponse(
            examId: "API001",
            examUrl: "https://api.test.com/exam",
            examTitle: "API Test Exam",
            duration: 60,
            lockMode: false
        )

        let session = ExamSession(from: response)

        #expect(session.examId == "API001")
        #expect(session.examUrl == "https://api.test.com/exam")
        #expect(session.examTitle == "API Test Exam")
        #expect(session.duration == 60)
        #expect(session.lockMode == false)
    }

    // MARK: - Session State Tests

    @Test("Starting session sets correct state")
    func testStartSession() {
        let session = ExamSession(
            examId: "TEST001",
            examUrl: "https://test.com",
            examTitle: "Test",
            duration: 30,
            lockMode: true
        )

        #expect(session.isActive == false)
        #expect(session.startTime == nil)

        session.start()

        #expect(session.isActive == true)
        #expect(session.startTime != nil)
        #expect(session.timeRemaining == 30 * 60) // duration in seconds
    }

    @Test("Ending session clears state")
    func testEndSession() {
        let session = ExamSession(
            examId: "TEST001",
            examUrl: "https://test.com",
            examTitle: "Test",
            duration: 30,
            lockMode: true
        )

        session.start()
        #expect(session.isActive == true)

        session.end()

        #expect(session.isActive == false)
        #expect(session.startTime == nil)
    }

    @Test("Calling start multiple times updates start time")
    func testMultipleStarts() {
        let session = ExamSession(
            examId: "TEST001",
            examUrl: "https://test.com",
            examTitle: "Test",
            duration: 30,
            lockMode: true
        )

        session.start()
        let firstStartTime = session.startTime

        // Small delay
        Thread.sleep(forTimeInterval: 0.1)

        session.start()
        let secondStartTime = session.startTime

        #expect(secondStartTime != firstStartTime)
        #expect(session.isActive == true)
    }

    // MARK: - Time Tracking Tests

    @Test("Update time remaining calculates correctly")
    func testUpdateTimeRemaining() async {
        let session = ExamSession(
            examId: "TEST001",
            examUrl: "https://test.com",
            examTitle: "Test",
            duration: 1, // 1 minute
            lockMode: true
        )

        session.start()
        let initialRemaining = session.timeRemaining
        #expect(initialRemaining == 60) // 60 seconds

        // Wait a bit
        try? await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds

        session.updateTimeRemaining()

        #expect(session.timeRemaining < initialRemaining)
        #expect(session.timeRemaining >= 58) // Should have decreased by ~1-2 seconds
    }

    @Test("Time remaining doesn't go below zero")
    func testTimeRemainingMinimum() async {
        let session = ExamSession(
            examId: "TEST001",
            examUrl: "https://test.com",
            examTitle: "Test",
            duration: 0, // 0 minutes
            lockMode: true
        )

        session.start()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        session.updateTimeRemaining()

        #expect(session.timeRemaining >= 0)
    }

    @Test("Is expired returns true when time is up")
    func testIsExpired() {
        let session = ExamSession(
            examId: "TEST001",
            examUrl: "https://test.com",
            examTitle: "Test",
            duration: 30,
            lockMode: true
        )

        session.start()
        #expect(session.isExpired == false)

        // Manually set time remaining to 0
        session.timeRemaining = 0
        #expect(session.isExpired == true)
    }

    @Test("Is expired returns false when session is not active")
    func testIsExpiredInactive() {
        let session = ExamSession(
            examId: "TEST001",
            examUrl: "https://test.com",
            examTitle: "Test",
            duration: 30,
            lockMode: true
        )

        session.timeRemaining = 0
        #expect(session.isExpired == false) // Not active, so not expired
    }

    // MARK: - Duration Conversion Tests

    @Test("Duration converts to seconds correctly")
    func testDurationToSeconds() {
        let session = ExamSession(
            examId: "TEST001",
            examUrl: "https://test.com",
            examTitle: "Test",
            duration: 45,
            lockMode: true
        )

        session.start()

        #expect(session.timeRemaining == 45 * 60) // 2700 seconds
    }

    @Test("Zero duration is handled correctly")
    func testZeroDuration() {
        let session = ExamSession(
            examId: "TEST001",
            examUrl: "https://test.com",
            examTitle: "Test",
            duration: 0,
            lockMode: true
        )

        session.start()

        #expect(session.timeRemaining == 0)
        #expect(session.isExpired == true)
    }

    // MARK: - Property Updates Tests

    @Test("Exam session properties are observable")
    func testObservableProperties() {
        let session = ExamSession()

        // These properties should be @Published and observable
        #expect(session.examId.isEmpty)
        session.examId = "NEW001"
        #expect(session.examId == "NEW001")

        #expect(session.isActive == false)
        session.isActive = true
        #expect(session.isActive == true)
    }
}
