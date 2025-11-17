//
//  UserModelTests.swift
//  MargaSatyaTests
//
//  Unit tests for User model
//

import Testing
import Foundation
@testable import MargaSatya

@Suite("User Model Tests")
struct UserModelTests {

    // MARK: - Initialization Tests

    @Test("User initialization with all properties")
    func testUserInitialization() {
        let user = User(
            id: "user123",
            name: "John Doe",
            email: "john@example.com",
            role: .teacher,
            authUID: "auth123"
        )

        #expect(user.id == "user123")
        #expect(user.name == "John Doe")
        #expect(user.email == "john@example.com")
        #expect(user.role == .teacher)
        #expect(user.authUID == "auth123")
        #expect(user.isActive == true)
    }

    @Test("User default values")
    func testUserDefaults() {
        let user = User(
            name: "Jane Doe",
            email: "jane@example.com",
            role: .admin
        )

        #expect(user.isActive == true)
        #expect(user.photoURL == nil)
        #expect(user.phoneNumber == nil)
    }

    // MARK: - Role Tests

    @Test("User role display names")
    func testRoleDisplayNames() {
        let admin = User(name: "Admin", email: "admin@test.com", role: .admin)
        let teacher = User(name: "Teacher", email: "teacher@test.com", role: .teacher)
        let student = User(name: "Student", email: "student@test.com", role: .student)

        #expect(admin.roleDisplayName == "Administrator")
        #expect(teacher.roleDisplayName == "Guru")
        #expect(student.roleDisplayName == "Siswa")
    }

    @Test("User role checks")
    func testRoleChecks() {
        let admin = User(name: "Admin", email: "admin@test.com", role: .admin)
        let teacher = User(name: "Teacher", email: "teacher@test.com", role: .teacher)

        #expect(admin.isAdmin == true)
        #expect(admin.isTeacher == false)
        #expect(teacher.isAdmin == false)
        #expect(teacher.isTeacher == true)
    }

    // MARK: - Permission Tests

    @Test("Admin permissions")
    func testAdminPermissions() {
        let admin = User(name: "Admin", email: "admin@test.com", role: .admin)

        #expect(admin.hasPermission(for: .manageStudents) == true)
        #expect(admin.hasPermission(for: .createExams) == true)
        #expect(admin.hasPermission(for: .viewAllExams) == true)
        #expect(admin.hasPermission(for: .manageAppConfig) == true)
        #expect(admin.hasPermission(for: .viewStatistics) == true)
        #expect(admin.hasPermission(for: .takeExam) == true)
    }

    @Test("Teacher permissions")
    func testTeacherPermissions() {
        let teacher = User(name: "Teacher", email: "teacher@test.com", role: .teacher)

        #expect(teacher.hasPermission(for: .manageStudents) == true)
        #expect(teacher.hasPermission(for: .createExams) == true)
        #expect(teacher.hasPermission(for: .viewAllExams) == false)
        #expect(teacher.hasPermission(for: .manageAppConfig) == false)
        #expect(teacher.hasPermission(for: .viewStatistics) == true)
        #expect(teacher.hasPermission(for: .takeExam) == true)
    }

    @Test("Student permissions")
    func testStudentPermissions() {
        let student = User(name: "Student", email: "student@test.com", role: .student)

        #expect(student.hasPermission(for: .manageStudents) == false)
        #expect(student.hasPermission(for: .createExams) == false)
        #expect(student.hasPermission(for: .viewAllExams) == false)
        #expect(student.hasPermission(for: .manageAppConfig) == false)
        #expect(student.hasPermission(for: .viewStatistics) == false)
        #expect(student.hasPermission(for: .takeExam) == true)
    }

    // MARK: - State Mutation Tests

    @Test("User activation and deactivation")
    func testActivationToggle() {
        var user = User(name: "Test", email: "test@test.com", role: .teacher)

        #expect(user.isActive == true)

        user.deactivate()
        #expect(user.isActive == false)

        user.activate()
        #expect(user.isActive == true)
    }

    @Test("Update last activity")
    func testUpdateLastActivity() {
        var user = User(name: "Test", email: "test@test.com", role: .teacher)
        let originalDate = user.updatedAt

        // Wait a tiny bit to ensure date changes
        Thread.sleep(forTimeInterval: 0.01)

        user.updateLastActivity()
        #expect(user.updatedAt > originalDate)
    }

    // MARK: - Equatable Tests

    @Test("User equality based on ID")
    func testUserEquality() {
        let user1 = User(id: "123", name: "User 1", email: "user1@test.com", role: .teacher)
        let user2 = User(id: "123", name: "User 2", email: "user2@test.com", role: .admin)
        let user3 = User(id: "456", name: "User 1", email: "user1@test.com", role: .teacher)

        #expect(user1 == user2) // Same ID
        #expect(user1 != user3) // Different ID
    }

    // MARK: - UserDTO Tests

    @Test("UserDTO conversion")
    func testUserDTOConversion() {
        let user = User(
            id: "user123",
            name: "John Doe",
            email: "john@example.com",
            role: .teacher,
            photoURL: "https://example.com/photo.jpg"
        )

        let dto = UserDTO(from: user)

        #expect(dto.id == "user123")
        #expect(dto.name == "John Doe")
        #expect(dto.email == "john@example.com")
        #expect(dto.role == "GURU")
        #expect(dto.photoURL == "https://example.com/photo.jpg")
    }
}
