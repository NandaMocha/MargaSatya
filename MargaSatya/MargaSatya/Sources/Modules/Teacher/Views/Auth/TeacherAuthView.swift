//
//  TeacherAuthView.swift
//  SecureExamID
//
//  Teacher authentication view dengan tab Login & Register
//

import SwiftUI

struct TeacherAuthView: View {

    // MARK: - State

    @StateObject private var viewModel: TeacherAuthViewModel
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init() {
        let container = DIContainer.shared
        _viewModel = StateObject(wrappedValue: container.makeTeacherAuthViewModel())
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            GlassBackground()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Tab Selector
                tabSelector

                // Tab Content
                TabView(selection: $selectedTab) {
                    loginTab
                        .tag(0)

                    registerTab
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $viewModel.isAuthenticated) {
            if let user = viewModel.currentUser {
                TeacherHomeView(user: user)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: UIConstants.Spacing.small) {
            Image(systemName: "person.text.rectangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Portal Guru")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Kelola ujian dan siswa Anda")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, UIConstants.Spacing.large)
        .padding(.bottom, UIConstants.Spacing.medium)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "Masuk", isSelected: selectedTab == 0) {
                withAnimation {
                    selectedTab = 0
                }
            }

            TabButton(title: "Daftar", isSelected: selectedTab == 1) {
                withAnimation {
                    selectedTab = 1
                }
            }
        }
        .padding(.horizontal, UIConstants.Spacing.large)
        .padding(.bottom, UIConstants.Spacing.medium)
    }

    // MARK: - Login Tab

    private var loginTab: some View {
        ScrollView {
            VStack(spacing: UIConstants.Spacing.large) {
                // Email Field
                VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                    Text("Email")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))

                    TextField("email@example.com", text: $viewModel.loginEmail)
                        .textFieldStyle(GlassTextFieldStyle())
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }

                // Password Field
                VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                    Text("Password")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))

                    SecureField("Password", text: $viewModel.loginPassword)
                        .textFieldStyle(GlassTextFieldStyle())
                        .textContentType(.password)
                }

                // Error Message
                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error) {
                        viewModel.clearError()
                    }
                }

                // Login Button
                GlassButton(
                    title: viewModel.isLoading ? "Memproses..." : "Masuk",
                    isEnabled: viewModel.isLoginValid && !viewModel.isLoading
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

    // MARK: - Register Tab

    private var registerTab: some View {
        ScrollView {
            VStack(spacing: UIConstants.Spacing.large) {
                // Name Field
                VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                    Text("Nama Lengkap")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))

                    TextField("Nama lengkap", text: $viewModel.registerName)
                        .textFieldStyle(GlassTextFieldStyle())
                        .textContentType(.name)
                }

                // Email Field
                VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                    Text("Email")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))

                    TextField("email@example.com", text: $viewModel.registerEmail)
                        .textFieldStyle(GlassTextFieldStyle())
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }

                // Password Field
                VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                    Text("Password")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))

                    SecureField("Minimal 8 karakter", text: $viewModel.registerPassword)
                        .textFieldStyle(GlassTextFieldStyle())
                        .textContentType(.newPassword)
                }

                // Confirm Password Field
                VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                    Text("Konfirmasi Password")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))

                    SecureField("Ulangi password", text: $viewModel.registerConfirmPassword)
                        .textFieldStyle(GlassTextFieldStyle())
                        .textContentType(.newPassword)
                }

                // Error Message
                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error) {
                        viewModel.clearError()
                    }
                }

                // Register Button
                GlassButton(
                    title: viewModel.isLoading ? "Memproses..." : "Daftar",
                    isEnabled: viewModel.isRegisterValid && !viewModel.isLoading
                ) {
                    Task {
                        await viewModel.register()
                    }
                }

                Spacer()
            }
            .padding(UIConstants.Spacing.large)
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: UIConstants.Spacing.small) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))

                Rectangle()
                    .fill(isSelected ? .white : .clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Glass Text Field Style

struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(UIConstants.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                    .fill(.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundStyle(.white)
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(UIConstants.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                .fill(.red.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TeacherAuthView()
    }
}
