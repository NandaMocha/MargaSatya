//
//  StudentEntryView.swift
//  SecureExamID
//
//  Student entry point (placeholder untuk Fase 6)
//

import SwiftUI

struct StudentEntryView: View {

    @State private var nis = ""
    @State private var examCode = ""

    var body: some View {
        ZStack {
            GlassBackground()

            VStack(spacing: UIConstants.Spacing.large) {
                // Header
                VStack(spacing: UIConstants.Spacing.small) {
                    Image(systemName: "person.fill.checkmark")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Portal Siswa")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Masukkan NIS dan kode ujian")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, UIConstants.Spacing.extraLarge)

                // Form
                VStack(spacing: UIConstants.Spacing.medium) {
                    VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                        Text("Nomor Induk Siswa (NIS)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))

                        TextField("Masukkan NIS", text: $nis)
                            .textFieldStyle(GlassTextFieldStyle())
                            .keyboardType(.numberPad)
                    }

                    VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                        Text("Kode Ujian")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))

                        TextField("Masukkan kode ujian", text: $examCode)
                            .textFieldStyle(GlassTextFieldStyle())
                            .textInputAutocapitalization(.characters)
                    }

                    // Placeholder message
                    VStack(spacing: UIConstants.Spacing.small) {
                        Text("🚧 Dalam Pengembangan 🚧")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("Fitur mengerjakan ujian\nakan tersedia di Fase 6")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(UIConstants.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                            .fill(.orange.opacity(0.2))
                    )

                    GlassButton(
                        title: "Mulai Ujian",
                        isEnabled: false
                    ) {
                        // Will be implemented in Fase 6
                    }
                }
                .padding(UIConstants.Spacing.large)

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StudentEntryView()
    }
}
