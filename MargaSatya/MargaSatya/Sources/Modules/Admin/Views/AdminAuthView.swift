//
//  AdminAuthView.swift
//  MargaSatya
//
//  Admin authentication dengan admin key
//

import SwiftUI

struct AdminAuthView: View {

    @StateObject private var viewModel: AdminAuthViewModel
    @Environment(\.dismiss) private var dismiss

    init() {
        let container = DIContainer.shared
        _viewModel = StateObject(wrappedValue: container.makeAdminAuthViewModel())
    }

    var body: some View {
        ZStack {
            GlassBackground()

            ScrollView {
                VStack(spacing: UIConstants.Spacing.large) {
                    // Header
                    headerSection

                    // Form
                    formSection

                    // Error
                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error) {
                            viewModel.clearError()
                        }
                    }

                    // Login Button
                    GlassButton(
                        title: viewModel.isLoading ? "Memproses..." : "Masuk",
                        isEnabled: viewModel.isValid && !viewModel.isLoading
                    ) {
                        Task {
                            await viewModel.login()
                        }
                    }

                    Spacer()
                }
                .padding(UIConstants.Spacing.large)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $viewModel.isAuthenticated) {
            if let user = viewModel.currentUser {
                AdminDashboardView(
                    user: user,
                    viewModel: DIContainer.shared.makeAdminDashboardViewModel()
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: UIConstants.Spacing.small) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Portal Admin")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Dashboard dan konfigurasi sistem")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, UIConstants.Spacing.extraLarge)
    }

    private var formSection: some View {
        VStack(spacing: UIConstants.Spacing.medium) {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                Text("Email")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))

                TextField("admin@example.com", text: $viewModel.email)
                    .textFieldStyle(GlassTextFieldStyle())
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }

            VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                Text("Password")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(GlassTextFieldStyle())
                    .textContentType(.password)
            }

            VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                HStack {
                    Text("Admin Key")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()

                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.purple.opacity(0.7))
                }

                SecureField("Kunci admin khusus", text: $viewModel.adminKey)
                    .textFieldStyle(GlassTextFieldStyle())
            }
        }
    }
}

// MARK: - Admin Auth ViewModel

@MainActor
final class AdminAuthViewModel: ObservableObject {

    @Published var email = ""
    @Published var password = ""
    @Published var adminKey = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    var isValid: Bool {
        !email.isEmpty && !password.isEmpty && !adminKey.isEmpty
    }

    func login() async {
        guard isValid else {
            errorMessage = "Semua field wajib diisi"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // For admin, we need to check if they're already registered
            // or register them with admin key
            let user = try await authService.login(email: email, password: password)

            guard user.role == .admin else {
                errorMessage = "Akun ini bukan akun admin"
                try? await authService.logout()
                isLoading = false
                return
            }

            currentUser = user
            isAuthenticated = true
            isLoading = false

        } catch {
            // If login fails, maybe they need to register
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func clearError() {
        errorMessage = nil
    }
}

#Preview {
    NavigationStack {
        AdminAuthView()
    }
}
