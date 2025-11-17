//
//  RoleSelectionView.swift
//  SecureExamID
//
//  Landing page untuk memilih role (Siswa, Guru, Admin)
//

import SwiftUI

// MARK: - Role Selection View

struct RoleSelectionView: View {

    // MARK: - State

    @State private var selectedRole: UserRole?
    @State private var showTeacherAuth = false
    @State private var showAdminAuth = false
    @State private var showStudentEntry = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                GlassBackground()

                // Content
                VStack(spacing: UIConstants.Spacing.extraLarge) {
                    Spacer()

                    // App Logo & Title
                    headerSection

                    Spacer()

                    // Role Selection Buttons
                    roleButtonsSection

                    Spacer()

                    // Footer
                    footerSection
                }
                .padding(UIConstants.Spacing.large)
            }
            .navigationDestination(isPresented: $showTeacherAuth) {
                TeacherAuthView()
            }
            .navigationDestination(isPresented: $showAdminAuth) {
                AdminAuthView()
            }
            .navigationDestination(isPresented: $showStudentEntry) {
                StudentEntryView()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: UIConstants.Spacing.medium) {
            // App Icon/Logo
            Image(systemName: "shield.checkered")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.5), radius: 20)

            // App Name
            Text(AppConfiguration.Info.name)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Tagline
            Text(AppConfiguration.Info.tagline)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Role Buttons Section

    private var roleButtonsSection: some View {
        VStack(spacing: UIConstants.Spacing.large) {
            // Student Button
            RoleButton(
                icon: "person.fill",
                title: "Masuk sebagai Siswa",
                description: "Ikuti ujian dengan kode akses",
                gradient: [.green, .teal]
            ) {
                showStudentEntry = true
            }

            // Teacher Button
            RoleButton(
                icon: "person.text.rectangle.fill",
                title: "Masuk sebagai Guru",
                description: "Kelola ujian dan siswa",
                gradient: [.blue, .cyan]
            ) {
                showTeacherAuth = true
            }

            // Admin Button
            RoleButton(
                icon: "crown.fill",
                title: "Admin",
                description: "Dashboard dan konfigurasi",
                gradient: [.purple, .pink]
            ) {
                showAdminAuth = true
            }
        }
        .padding(.horizontal, UIConstants.Spacing.medium)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: UIConstants.Spacing.small) {
            Text("Versi \(AppConfiguration.Info.version)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))

            Text("© 2024 SecureExamID")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

// MARK: - Role Button Component

struct RoleButton: View {

    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: UIConstants.Spacing.medium) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.1))
                    )

                // Text
                VStack(alignment: .leading, spacing: UIConstants.Spacing.extraSmall) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(UIConstants.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                    .fill(.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    RoleSelectionView()
}
