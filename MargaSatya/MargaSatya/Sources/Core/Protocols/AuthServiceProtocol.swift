//
//  AuthServiceProtocol.swift
//  SecureExamID
//
//  Protocol for authentication operations
//

import Foundation

// MARK: - Auth Service Protocol

protocol AuthServiceProtocol {
    /// Current authenticated user
    var currentUser: User? { get }

    /// Register new teacher
    func registerTeacher(
        name: String,
        email: String,
        password: String
    ) async throws -> User

    /// Register new admin
    func registerAdmin(
        name: String,
        email: String,
        password: String,
        adminKey: String
    ) async throws -> User

    /// Login with email and password
    func login(
        email: String,
        password: String
    ) async throws -> User

    /// Logout current user
    func logout() async throws

    /// Check if user is authenticated
    var isAuthenticated: Bool { get }

    /// Get user by ID
    func getUser(userId: String) async throws -> User?

    /// Update user profile
    func updateUser(_ user: User) async throws

    /// Change password
    func changePassword(
        currentPassword: String,
        newPassword: String
    ) async throws

    /// Reset password via email
    func resetPassword(email: String) async throws
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case invalidAdminKey
    case notAuthenticated
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Email tidak valid"
        case .weakPassword:
            return "Password terlalu lemah (minimal 8 karakter)"
        case .emailAlreadyInUse:
            return "Email sudah terdaftar"
        case .userNotFound:
            return "User tidak ditemukan"
        case .wrongPassword:
            return "Password salah"
        case .invalidAdminKey:
            return "Kunci admin tidak valid"
        case .notAuthenticated:
            return "Anda belum login"
        case .permissionDenied:
            return "Anda tidak memiliki izin"
        }
    }
}
