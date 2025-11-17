//
//  TeacherAuthViewModel.swift
//  SecureExamID
//
//  ViewModel untuk Teacher authentication (login & register)
//

import Foundation
import SwiftUI

@MainActor
final class TeacherAuthViewModel: ObservableObject {

    // MARK: - Published Properties

    // Login
    @Published var loginEmail = ""
    @Published var loginPassword = ""

    // Register
    @Published var registerName = ""
    @Published var registerEmail = ""
    @Published var registerPassword = ""
    @Published var registerConfirmPassword = ""

    // State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol

    // MARK: - Initialization

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    // MARK: - Validation

    var isLoginValid: Bool {
        !loginEmail.isEmpty && !loginPassword.isEmpty
    }

    var isRegisterValid: Bool {
        !registerName.isEmpty &&
        !registerEmail.isEmpty &&
        !registerPassword.isEmpty &&
        registerPassword == registerConfirmPassword &&
        isEmailValid(registerEmail) &&
        registerPassword.count >= AppConfiguration.Auth.minPasswordLength
    }

    var registerValidationErrors: [String] {
        var errors: [String] = []

        if registerName.isEmpty {
            errors.append("Nama lengkap wajib diisi")
        }

        if registerEmail.isEmpty {
            errors.append("Email wajib diisi")
        } else if !isEmailValid(registerEmail) {
            errors.append("Format email tidak valid")
        }

        if registerPassword.isEmpty {
            errors.append("Password wajib diisi")
        } else if registerPassword.count < AppConfiguration.Auth.minPasswordLength {
            errors.append("Password minimal \(AppConfiguration.Auth.minPasswordLength) karakter")
        }

        if registerPassword != registerConfirmPassword {
            errors.append("Konfirmasi password tidak cocok")
        }

        return errors
    }

    // MARK: - Actions

    func login() async {
        guard isLoginValid else {
            errorMessage = "Email dan password wajib diisi"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.login(
                email: loginEmail,
                password: loginPassword
            )

            // Verify role
            guard user.role == .teacher else {
                errorMessage = "Akun ini bukan akun guru"
                try? await authService.logout()
                isLoading = false
                return
            }

            currentUser = user
            isAuthenticated = true
            isLoading = false

        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func register() async {
        guard isRegisterValid else {
            errorMessage = registerValidationErrors.first ?? "Data tidak lengkap"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.registerTeacher(
                name: registerName,
                email: registerEmail,
                password: registerPassword
            )

            currentUser = user
            isAuthenticated = true
            isLoading = false

        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func logout() async {
        do {
            try await authService.logout()
            currentUser = nil
            isAuthenticated = false
            clearFields()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func isEmailValid(_ email: String) -> Bool {
        let emailRegex = AppConfiguration.Validation.emailPattern
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func clearFields() {
        loginEmail = ""
        loginPassword = ""
        registerName = ""
        registerEmail = ""
        registerPassword = ""
        registerConfirmPassword = ""
        errorMessage = nil
    }

    func clearError() {
        errorMessage = nil
    }
}
