//
//  FirebaseAuthService.swift
//  SecureExamID
//
//  Firebase Authentication implementation
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Firebase Auth Service

final class FirebaseAuthService: AuthServiceProtocol {

    // MARK: - Properties

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let usersCollection = AppConfiguration.Firebase.Collections.users

    var currentUser: User? {
        get async {
            guard let firebaseUser = auth.currentUser else {
                return nil
            }

            // Fetch user from Firestore
            return try? await getUser(userId: firebaseUser.uid)
        }
    }

    var isAuthenticated: Bool {
        return auth.currentUser != nil
    }

    // MARK: - Register

    func registerTeacher(name: String, email: String, password: String) async throws -> User {
        // Validate password
        guard password.count >= AppConfiguration.Auth.minPasswordLength else {
            throw AuthError.weakPassword
        }

        // Create Firebase Auth user
        let authResult = try await auth.createUser(withEmail: email, password: password)

        // Create User document in Firestore
        let newUser = User(
            id: authResult.user.uid,
            name: name,
            email: email,
            role: .teacher,
            authUID: authResult.user.uid
        )

        try db.collection(usersCollection)
            .document(authResult.user.uid)
            .setData(from: newUser)

        return newUser
    }

    func registerAdmin(name: String, email: String, password: String, adminKey: String) async throws -> User {
        // Validate admin key
        guard adminKey == AppConfiguration.Auth.adminRegistrationKey else {
            throw AuthError.invalidAdminKey
        }

        // Validate password
        guard password.count >= AppConfiguration.Auth.minPasswordLength else {
            throw AuthError.weakPassword
        }

        // Create Firebase Auth user
        let authResult = try await auth.createUser(withEmail: email, password: password)

        // Create Admin user document
        let newUser = User(
            id: authResult.user.uid,
            name: name,
            email: email,
            role: .admin,
            authUID: authResult.user.uid
        )

        try db.collection(usersCollection)
            .document(authResult.user.uid)
            .setData(from: newUser)

        return newUser
    }

    // MARK: - Login

    func login(email: String, password: String) async throws -> User {
        // Sign in with Firebase Auth
        let authResult = try await auth.signIn(withEmail: email, password: password)

        // Fetch user from Firestore
        guard let user = try await getUser(userId: authResult.user.uid) else {
            throw AuthError.userNotFound
        }

        return user
    }

    // MARK: - Logout

    func logout() async throws {
        try auth.signOut()
    }

    // MARK: - User Management

    func getUser(userId: String) async throws -> User? {
        let document = try await db.collection(usersCollection)
            .document(userId)
            .getDocument()

        guard document.exists else {
            return nil
        }

        return try document.data(as: User.self)
    }

    func updateUser(_ user: User) async throws {
        guard let userId = user.id else {
            throw AuthError.userNotFound
        }

        try db.collection(usersCollection)
            .document(userId)
            .setData(from: user, merge: true)
    }

    // MARK: - Password Management

    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = auth.currentUser, let email = user.email else {
            throw AuthError.notAuthenticated
        }

        // Validate new password
        guard newPassword.count >= AppConfiguration.Auth.minPasswordLength else {
            throw AuthError.weakPassword
        }

        // Re-authenticate first
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await user.reauthenticate(with: credential)

        // Update password
        try await user.updatePassword(to: newPassword)
    }

    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
}

// MARK: - Mock Auth Service

final class MockAuthService: AuthServiceProtocol {

    // MARK: - Properties

    private var users: [User] = []
    private var _currentUser: User?
    var shouldFailOperations = false

    var currentUser: User? {
        return _currentUser
    }

    var isAuthenticated: Bool {
        return _currentUser != nil
    }

    // MARK: - Test Helpers

    func setCurrentUser(_ user: User?) {
        _currentUser = user
    }

    func addMockUser(_ user: User) {
        users.append(user)
    }

    func reset() {
        users.removeAll()
        _currentUser = nil
    }

    // MARK: - Implementation

    func registerTeacher(name: String, email: String, password: String) async throws -> User {
        if shouldFailOperations {
            throw AuthError.permissionDenied
        }

        guard password.count >= AppConfiguration.Auth.minPasswordLength else {
            throw AuthError.weakPassword
        }

        // Check if email exists
        if users.contains(where: { $0.email == email }) {
            throw AuthError.emailAlreadyInUse
        }

        let newUser = User(
            id: UUID().uuidString,
            name: name,
            email: email,
            role: .teacher,
            authUID: UUID().uuidString
        )

        users.append(newUser)
        _currentUser = newUser
        return newUser
    }

    func registerAdmin(name: String, email: String, password: String, adminKey: String) async throws -> User {
        if shouldFailOperations {
            throw AuthError.permissionDenied
        }

        guard adminKey == AppConfiguration.Auth.adminRegistrationKey else {
            throw AuthError.invalidAdminKey
        }

        guard password.count >= AppConfiguration.Auth.minPasswordLength else {
            throw AuthError.weakPassword
        }

        if users.contains(where: { $0.email == email }) {
            throw AuthError.emailAlreadyInUse
        }

        let newUser = User(
            id: UUID().uuidString,
            name: name,
            email: email,
            role: .admin,
            authUID: UUID().uuidString
        )

        users.append(newUser)
        _currentUser = newUser
        return newUser
    }

    func login(email: String, password: String) async throws -> User {
        if shouldFailOperations {
            throw AuthError.permissionDenied
        }

        guard let user = users.first(where: { $0.email == email }) else {
            throw AuthError.userNotFound
        }

        // Mock: don't actually validate password
        _currentUser = user
        return user
    }

    func logout() async throws {
        if shouldFailOperations {
            throw AuthError.permissionDenied
        }

        _currentUser = nil
    }

    func getUser(userId: String) async throws -> User? {
        if shouldFailOperations {
            throw AuthError.permissionDenied
        }

        return users.first { $0.id == userId }
    }

    func updateUser(_ user: User) async throws {
        if shouldFailOperations {
            throw AuthError.permissionDenied
        }

        guard let index = users.firstIndex(where: { $0.id == user.id }) else {
            throw AuthError.userNotFound
        }

        users[index] = user

        if _currentUser?.id == user.id {
            _currentUser = user
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        if shouldFailOperations {
            throw AuthError.permissionDenied
        }

        guard _currentUser != nil else {
            throw AuthError.notAuthenticated
        }

        guard newPassword.count >= AppConfiguration.Auth.minPasswordLength else {
            throw AuthError.weakPassword
        }

        // Mock: just validate, don't actually change
    }

    func resetPassword(email: String) async throws {
        if shouldFailOperations {
            throw AuthError.permissionDenied
        }

        guard users.contains(where: { $0.email == email }) else {
            throw AuthError.userNotFound
        }

        // Mock: just validate email exists
    }
}
