//
//  FirebaseAuthServiceTests.swift
//  MargaSatyaTests
//
//  Critical tests for authentication and authorization
//  Tests registration, login, role-based access, and security
//

import Testing
import Foundation
@testable import MargaSatya

@Suite("Firebase Auth Service Tests")
struct FirebaseAuthServiceTests {

    // MARK: - Test Properties

    let mockService: MockAuthService

    init() {
        self.mockService = MockAuthService()
    }

    // MARK: - Teacher Registration Tests

    @Test("Register teacher successfully")
    func testRegisterTeacher_Success() async throws {
        // Arrange
        let name = "John Doe"
        let email = "john@teacher.com"
        let password = "SecurePass123"

        // Act
        let user = try await mockService.registerTeacher(
            name: name,
            email: email,
            password: password
        )

        // Assert
        #expect(user.id != nil)
        #expect(user.name == name)
        #expect(user.email == email)
        #expect(user.role == .teacher)
        #expect(user.authUID != nil)
        #expect(user.isActive == true)
        #expect(mockService.currentUser?.id == user.id)
    }

    @Test("Register teacher with weak password fails")
    func testRegisterTeacher_WeakPassword() async {
        // Arrange
        let shortPassword = "short" // Less than 8 characters

        // Act & Assert
        await #expect(throws: AuthError.weakPassword) {
            try await mockService.registerTeacher(
                name: "Teacher",
                email: "teacher@test.com",
                password: shortPassword
            )
        }
    }

    @Test("Register teacher with duplicate email fails")
    func testRegisterTeacher_DuplicateEmail() async throws {
        // Arrange
        let email = "duplicate@teacher.com"
        _ = try await mockService.registerTeacher(
            name: "First Teacher",
            email: email,
            password: "Password123"
        )

        // Act & Assert
        await #expect(throws: AuthError.emailAlreadyInUse) {
            try await mockService.registerTeacher(
                name: "Second Teacher",
                email: email,
                password: "Password456"
            )
        }
    }

    @Test("Register teacher sets current user")
    func testRegisterTeacher_SetsCurrentUser() async throws {
        // Act
        let user = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "Password123"
        )

        // Assert
        #expect(mockService.isAuthenticated == true)
        #expect(mockService.currentUser?.id == user.id)
    }

    // MARK: - Admin Registration Tests

    @Test("Register admin successfully with valid admin key")
    func testRegisterAdmin_Success() async throws {
        // Arrange
        let name = "Admin User"
        let email = "admin@system.com"
        let password = "AdminPass123"
        let adminKey = "ADMIN-SECURE-2024"

        // Act
        let user = try await mockService.registerAdmin(
            name: name,
            email: email,
            password: password,
            adminKey: adminKey
        )

        // Assert
        #expect(user.id != nil)
        #expect(user.name == name)
        #expect(user.email == email)
        #expect(user.role == .admin)
        #expect(user.authUID != nil)
        #expect(mockService.currentUser?.id == user.id)
    }

    @Test("Register admin with invalid admin key fails")
    func testRegisterAdmin_InvalidAdminKey() async {
        // Arrange
        let invalidKey = "WRONG-KEY"

        // Act & Assert
        await #expect(throws: AuthError.invalidAdminKey) {
            try await mockService.registerAdmin(
                name: "Fake Admin",
                email: "fake@admin.com",
                password: "Password123",
                adminKey: invalidKey
            )
        }
    }

    @Test("Register admin with weak password fails")
    func testRegisterAdmin_WeakPassword() async {
        // Arrange
        let validAdminKey = "ADMIN-SECURE-2024"
        let weakPassword = "weak"

        // Act & Assert
        await #expect(throws: AuthError.weakPassword) {
            try await mockService.registerAdmin(
                name: "Admin",
                email: "admin@test.com",
                password: weakPassword,
                adminKey: validAdminKey
            )
        }
    }

    @Test("Register admin with duplicate email fails")
    func testRegisterAdmin_DuplicateEmail() async throws {
        // Arrange
        let email = "duplicate@admin.com"
        let adminKey = "ADMIN-SECURE-2024"

        _ = try await mockService.registerTeacher(
            name: "Teacher",
            email: email,
            password: "Password123"
        )

        // Act & Assert
        await #expect(throws: AuthError.emailAlreadyInUse) {
            try await mockService.registerAdmin(
                name: "Admin",
                email: email,
                password: "Password456",
                adminKey: adminKey
            )
        }
    }

    @Test("Admin registration requires exact admin key match")
    func testRegisterAdmin_AdminKeyValidation() async {
        // Test various invalid keys
        let invalidKeys = [
            "admin-secure-2024", // Wrong case
            "ADMIN-SECURE-2024 ", // Extra space
            " ADMIN-SECURE-2024", // Leading space
            "ADMIN-SECURE-2023", // Wrong year
            ""
        ]

        for invalidKey in invalidKeys {
            await #expect(throws: AuthError.invalidAdminKey) {
                try await mockService.registerAdmin(
                    name: "Admin",
                    email: "admin\(invalidKey.count)@test.com",
                    password: "Password123",
                    adminKey: invalidKey
                )
            }
        }
    }

    // MARK: - Login Tests

    @Test("Login with valid credentials")
    func testLogin_Success() async throws {
        // Arrange
        let email = "teacher@test.com"
        let password = "Password123"

        _ = try await mockService.registerTeacher(
            name: "Teacher",
            email: email,
            password: password
        )

        // Logout first
        try await mockService.logout()

        // Act
        let user = try await mockService.login(email: email, password: password)

        // Assert
        #expect(user.email == email)
        #expect(user.role == .teacher)
        #expect(mockService.isAuthenticated == true)
        #expect(mockService.currentUser?.id == user.id)
    }

    @Test("Login with non-existent user fails")
    func testLogin_UserNotFound() async {
        // Act & Assert
        await #expect(throws: AuthError.userNotFound) {
            try await mockService.login(
                email: "nonexistent@test.com",
                password: "Password123"
            )
        }
    }

    @Test("Login with admin account")
    func testLogin_AdminAccount() async throws {
        // Arrange
        let email = "admin@test.com"
        let password = "AdminPass123"

        _ = try await mockService.registerAdmin(
            name: "Admin",
            email: email,
            password: password,
            adminKey: "ADMIN-SECURE-2024"
        )

        try await mockService.logout()

        // Act
        let user = try await mockService.login(email: email, password: password)

        // Assert
        #expect(user.role == .admin)
        #expect(mockService.isAuthenticated == true)
    }

    @Test("Login updates current user")
    func testLogin_UpdatesCurrentUser() async throws {
        // Arrange
        let user1 = try await mockService.registerTeacher(
            name: "Teacher 1",
            email: "teacher1@test.com",
            password: "Password123"
        )

        try await mockService.logout()

        let user2 = try await mockService.registerTeacher(
            name: "Teacher 2",
            email: "teacher2@test.com",
            password: "Password456"
        )

        try await mockService.logout()

        // Act - Login as first user
        let loggedInUser = try await mockService.login(
            email: "teacher1@test.com",
            password: "Password123"
        )

        // Assert
        #expect(loggedInUser.id == user1.id)
        #expect(mockService.currentUser?.id == user1.id)
        #expect(mockService.currentUser?.id != user2.id)
    }

    // MARK: - Logout Tests

    @Test("Logout clears current user")
    func testLogout_ClearsCurrentUser() async throws {
        // Arrange
        _ = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "Password123"
        )

        #expect(mockService.isAuthenticated == true)

        // Act
        try await mockService.logout()

        // Assert
        #expect(mockService.isAuthenticated == false)
        #expect(mockService.currentUser == nil)
    }

    @Test("Logout can be called multiple times")
    func testLogout_MultipleCalls() async throws {
        // Arrange
        _ = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "Password123"
        )

        // Act & Assert - Should not throw
        try await mockService.logout()
        try await mockService.logout()
        try await mockService.logout()

        #expect(mockService.currentUser == nil)
    }

    // MARK: - Get User Tests

    @Test("Get user by ID returns correct user")
    func testGetUser_Success() async throws {
        // Arrange
        let registered = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "Password123"
        )

        // Act
        let retrieved = try await mockService.getUser(userId: registered.id!)

        // Assert
        #expect(retrieved != nil)
        #expect(retrieved?.id == registered.id)
        #expect(retrieved?.email == registered.email)
        #expect(retrieved?.role == registered.role)
    }

    @Test("Get user returns nil for non-existent ID")
    func testGetUser_NotFound() async throws {
        // Act
        let user = try await mockService.getUser(userId: "non-existent-id")

        // Assert
        #expect(user == nil)
    }

    @Test("Get user works for different roles")
    func testGetUser_DifferentRoles() async throws {
        // Arrange
        let teacher = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "Password123"
        )

        try await mockService.logout()

        let admin = try await mockService.registerAdmin(
            name: "Admin",
            email: "admin@test.com",
            password: "Password123",
            adminKey: "ADMIN-SECURE-2024"
        )

        // Act
        let retrievedTeacher = try await mockService.getUser(userId: teacher.id!)
        let retrievedAdmin = try await mockService.getUser(userId: admin.id!)

        // Assert
        #expect(retrievedTeacher?.role == .teacher)
        #expect(retrievedAdmin?.role == .admin)
    }

    // MARK: - Update User Tests

    @Test("Update user successfully")
    func testUpdateUser_Success() async throws {
        // Arrange
        var user = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "Password123"
        )

        // Modify user
        user.phoneNumber = "081234567890"
        user.photoURL = "https://example.com/photo.jpg"

        // Act
        try await mockService.updateUser(user)

        // Assert
        let updated = try await mockService.getUser(userId: user.id!)
        #expect(updated?.phoneNumber == "081234567890")
        #expect(updated?.photoURL == "https://example.com/photo.jpg")
    }

    @Test("Update user updates current user if same")
    func testUpdateUser_UpdatesCurrentUser() async throws {
        // Arrange
        var user = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "Password123"
        )

        user.name = "Updated Name"

        // Act
        try await mockService.updateUser(user)

        // Assert
        #expect(mockService.currentUser?.name == "Updated Name")
    }

    @Test("Update non-existent user fails")
    func testUpdateUser_NotFound() async {
        // Arrange
        let nonExistentUser = User(
            id: "non-existent",
            name: "Test",
            email: "test@test.com",
            role: .teacher
        )

        // Act & Assert
        await #expect(throws: AuthError.userNotFound) {
            try await mockService.updateUser(nonExistentUser)
        }
    }

    @Test("Update user without ID fails")
    func testUpdateUser_NoId() async {
        // Arrange
        let userWithoutId = User(
            id: nil,
            name: "Test",
            email: "test@test.com",
            role: .teacher
        )

        // Act & Assert
        await #expect(throws: AuthError.userNotFound) {
            try await mockService.updateUser(userWithoutId)
        }
    }

    // MARK: - Change Password Tests

    @Test("Change password successfully")
    func testChangePassword_Success() async throws {
        // Arrange
        _ = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "OldPassword123"
        )

        // Act & Assert - Should not throw
        try await mockService.changePassword(
            currentPassword: "OldPassword123",
            newPassword: "NewPassword456"
        )
    }

    @Test("Change password with weak new password fails")
    func testChangePassword_WeakNewPassword() async throws {
        // Arrange
        _ = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "OldPassword123"
        )

        // Act & Assert
        await #expect(throws: AuthError.weakPassword) {
            try await mockService.changePassword(
                currentPassword: "OldPassword123",
                newPassword: "weak"
            )
        }
    }

    @Test("Change password when not authenticated fails")
    func testChangePassword_NotAuthenticated() async {
        // Act & Assert
        await #expect(throws: AuthError.notAuthenticated) {
            try await mockService.changePassword(
                currentPassword: "OldPassword123",
                newPassword: "NewPassword456"
            )
        }
    }

    @Test("Change password validates minimum length")
    func testChangePassword_MinimumLength() async throws {
        // Arrange
        _ = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "OldPassword123"
        )

        // Test exactly 8 characters (minimum) - should succeed
        try await mockService.changePassword(
            currentPassword: "OldPassword123",
            newPassword: "12345678"
        )

        // Test 7 characters - should fail
        await #expect(throws: AuthError.weakPassword) {
            try await mockService.changePassword(
                currentPassword: "OldPassword123",
                newPassword: "1234567"
            )
        }
    }

    // MARK: - Reset Password Tests

    @Test("Reset password for existing user")
    func testResetPassword_Success() async throws {
        // Arrange
        let email = "teacher@test.com"
        _ = try await mockService.registerTeacher(
            name: "Teacher",
            email: email,
            password: "Password123"
        )

        // Act & Assert - Should not throw
        try await mockService.resetPassword(email: email)
    }

    @Test("Reset password for non-existent user fails")
    func testResetPassword_UserNotFound() async {
        // Act & Assert
        await #expect(throws: AuthError.userNotFound) {
            try await mockService.resetPassword(email: "nonexistent@test.com")
        }
    }

    @Test("Reset password works for both teachers and admins")
    func testResetPassword_DifferentRoles() async throws {
        // Arrange
        let teacherEmail = "teacher@test.com"
        let adminEmail = "admin@test.com"

        _ = try await mockService.registerTeacher(
            name: "Teacher",
            email: teacherEmail,
            password: "Password123"
        )

        try await mockService.logout()

        _ = try await mockService.registerAdmin(
            name: "Admin",
            email: adminEmail,
            password: "Password123",
            adminKey: "ADMIN-SECURE-2024"
        )

        // Act & Assert - Both should succeed
        try await mockService.resetPassword(email: teacherEmail)
        try await mockService.resetPassword(email: adminEmail)
    }

    // MARK: - Current User Tests

    @Test("Current user is nil when not authenticated")
    func testCurrentUser_NotAuthenticated() {
        // Assert
        #expect(mockService.currentUser == nil)
        #expect(mockService.isAuthenticated == false)
    }

    @Test("Current user is set after registration")
    func testCurrentUser_AfterRegistration() async throws {
        // Act
        let user = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "Password123"
        )

        // Assert
        #expect(mockService.currentUser != nil)
        #expect(mockService.currentUser?.id == user.id)
        #expect(mockService.isAuthenticated == true)
    }

    @Test("Current user persists across operations")
    func testCurrentUser_PersistsAcrossOperations() async throws {
        // Arrange
        let user = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "Password123"
        )

        // Act - Perform various operations
        _ = try await mockService.getUser(userId: user.id!)
        var updatedUser = user
        updatedUser.phoneNumber = "123456"
        try await mockService.updateUser(updatedUser)

        // Assert - Current user should still be set
        #expect(mockService.currentUser != nil)
        #expect(mockService.currentUser?.id == user.id)
        #expect(mockService.isAuthenticated == true)
    }

    // MARK: - Error Handling Tests

    @Test("Service fails when shouldFailOperations is true")
    func testServiceFailure_AllOperations() async throws {
        // Arrange
        mockService.shouldFailOperations = true

        // Register Teacher
        await #expect(throws: AuthError.permissionDenied) {
            try await mockService.registerTeacher(
                name: "Teacher",
                email: "teacher@test.com",
                password: "Password123"
            )
        }

        // Register Admin
        await #expect(throws: AuthError.permissionDenied) {
            try await mockService.registerAdmin(
                name: "Admin",
                email: "admin@test.com",
                password: "Password123",
                adminKey: "ADMIN-SECURE-2024"
            )
        }

        // Login
        await #expect(throws: AuthError.permissionDenied) {
            try await mockService.login(email: "test@test.com", password: "Password123")
        }

        // Logout
        await #expect(throws: AuthError.permissionDenied) {
            try await mockService.logout()
        }

        // Get User
        await #expect(throws: AuthError.permissionDenied) {
            try await mockService.getUser(userId: "test-id")
        }

        // Update User
        let testUser = User(id: "test", name: "Test", email: "test@test.com", role: .teacher)
        await #expect(throws: AuthError.permissionDenied) {
            try await mockService.updateUser(testUser)
        }

        // Change Password
        await #expect(throws: AuthError.permissionDenied) {
            try await mockService.changePassword(currentPassword: "old", newPassword: "newPassword123")
        }

        // Reset Password
        await #expect(throws: AuthError.permissionDenied) {
            try await mockService.resetPassword(email: "test@test.com")
        }
    }

    // MARK: - Role-Based Access Tests

    @Test("Teacher and admin have different roles")
    func testRoles_TeacherVsAdmin() async throws {
        // Arrange
        let teacher = try await mockService.registerTeacher(
            name: "Teacher",
            email: "teacher@test.com",
            password: "Password123"
        )

        try await mockService.logout()

        let admin = try await mockService.registerAdmin(
            name: "Admin",
            email: "admin@test.com",
            password: "Password123",
            adminKey: "ADMIN-SECURE-2024"
        )

        // Assert
        #expect(teacher.role == .teacher)
        #expect(admin.role == .admin)
        #expect(teacher.role != admin.role)
    }

    @Test("Multiple teachers can register independently")
    func testRoles_MultipleTeachers() async throws {
        // Arrange & Act
        let teacher1 = try await mockService.registerTeacher(
            name: "Teacher 1",
            email: "teacher1@test.com",
            password: "Password123"
        )

        try await mockService.logout()

        let teacher2 = try await mockService.registerTeacher(
            name: "Teacher 2",
            email: "teacher2@test.com",
            password: "Password456"
        )

        // Assert
        #expect(teacher1.role == .teacher)
        #expect(teacher2.role == .teacher)
        #expect(teacher1.id != teacher2.id)
        #expect(teacher1.email != teacher2.email)
    }

    @Test("Multiple admins can register with valid admin key")
    func testRoles_MultipleAdmins() async throws {
        // Arrange & Act
        let admin1 = try await mockService.registerAdmin(
            name: "Admin 1",
            email: "admin1@test.com",
            password: "Password123",
            adminKey: "ADMIN-SECURE-2024"
        )

        try await mockService.logout()

        let admin2 = try await mockService.registerAdmin(
            name: "Admin 2",
            email: "admin2@test.com",
            password: "Password456",
            adminKey: "ADMIN-SECURE-2024"
        )

        // Assert
        #expect(admin1.role == .admin)
        #expect(admin2.role == .admin)
        #expect(admin1.id != admin2.id)
    }

    // MARK: - Reset Tests

    @Test("Reset clears all users and current user")
    func testReset_ClearsAllData() async throws {
        // Arrange
        _ = try await mockService.registerTeacher(
            name: "Teacher 1",
            email: "teacher1@test.com",
            password: "Password123"
        )

        try await mockService.logout()

        _ = try await mockService.registerTeacher(
            name: "Teacher 2",
            email: "teacher2@test.com",
            password: "Password456"
        )

        // Verify state before reset
        #expect(mockService.isAuthenticated == true)

        // Act
        mockService.reset()

        // Assert
        #expect(mockService.currentUser == nil)
        #expect(mockService.isAuthenticated == false)

        // Try to login with previous credentials - should fail
        await #expect(throws: AuthError.userNotFound) {
            try await mockService.login(email: "teacher1@test.com", password: "Password123")
        }
    }
}
