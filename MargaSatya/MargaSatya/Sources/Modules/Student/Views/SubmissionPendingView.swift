//
//  SubmissionPendingView.swift
//  MargaSatya
//
//  View shown when exam submission is pending due to network issues
//

import SwiftUI

struct SubmissionPendingView: View {

    // MARK: - Properties

    let session: ExamSession

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                VStack(spacing: 32) {
                    Spacer()

                    // Warning Icon
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Message
                    VStack(spacing: 16) {
                        Text("Pengiriman Tertunda")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Jawaban Anda telah tersimpan, tetapi tidak dapat dikirim karena tidak ada koneksi internet.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Info Card
                    VStack(alignment: .leading, spacing: 16) {
                        InfoRow(
                            icon: "checkmark.shield.fill",
                            title: "Jawaban Tersimpan",
                            description: "Semua jawaban Anda telah disimpan dengan aman dan terenkripsi"
                        )

                        InfoRow(
                            icon: "arrow.clockwise",
                            title: "Pengiriman Otomatis",
                            description: "Jawaban akan terkirim otomatis saat koneksi internet tersedia"
                        )

                        InfoRow(
                            icon: "lock.fill",
                            title: "Aman & Terenkripsi",
                            description: "Data jawaban Anda dilindungi dengan enkripsi AES-256"
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal)

                    // Note
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Catatan Penting")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Hubungi guru Anda jika jawaban belum terkirim dalam 24 jam")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue.opacity(0.1))
                    )
                    .padding(.horizontal)

                    Spacer()

                    // Done Button
                    Button {
                        dismiss()
                    } label: {
                        Text("Mengerti")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
