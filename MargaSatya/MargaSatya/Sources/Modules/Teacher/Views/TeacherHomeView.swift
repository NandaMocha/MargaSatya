//
//  TeacherHomeView.swift
//  SecureExamID
//
//  Teacher dashboard (placeholder untuk Fase 4)
//

import SwiftUI

struct TeacherHomeView: View {

    let user: User

    var body: some View {
        ZStack {
            GlassBackground()

            VStack(spacing: UIConstants.Spacing.large) {
                // Header
                VStack(spacing: UIConstants.Spacing.small) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Selamat Datang, \(user.name)!")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Portal Guru")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, UIConstants.Spacing.extraLarge)

                Spacer()

                // Placeholder content
                VStack(spacing: UIConstants.Spacing.medium) {
                    Text("🚧 Dalam Pengembangan 🚧")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("Fitur manajemen siswa dan ujian\nakan tersedia di Fase 4")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(UIConstants.Spacing.large)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
                        .fill(.white.opacity(0.1))
                )
                .padding(.horizontal, UIConstants.Spacing.large)

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        TeacherHomeView(
            user: User(
                name: "John Doe",
                email: "john@example.com",
                role: .teacher
            )
        )
    }
}
