//
//  TeacherStatsView.swift
//  MargaSatya
//
//  Detailed statistics view for a specific teacher
//

import SwiftUI

struct TeacherStatsView: View {

    // MARK: - Properties

    let teacher: User
    @StateObject private var viewModel: TeacherStatsViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(teacher: User, viewModel: TeacherStatsViewModel) {
        self.teacher = teacher
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            GlassBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Teacher Header
                    teacherHeader

                    // Stats
                    if viewModel.isLoading && !viewModel.hasStats {
                        loadingView
                    } else if viewModel.hasStats {
                        statsSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Statistik Guru")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Tutup") {
                    dismiss()
                }
            }
        }
        .alert("Kesalahan", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.showError = false
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            await viewModel.loadStats()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - View Components

    private var teacherHeader: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay {
                    Text(teacher.name.prefix(1).uppercased())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

            Text(teacher.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(teacher.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("Statistik")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    icon: "person.3.fill",
                    title: "Total Siswa",
                    value: "\(viewModel.totalStudents)",
                    color: .green,
                    gradient: [.green, .mint]
                )

                StatCard(
                    icon: "doc.text.fill",
                    title: "Total Ujian",
                    value: "\(viewModel.totalExams)",
                    color: .purple,
                    gradient: [.purple, .pink]
                )

                StatCard(
                    icon: "play.circle.fill",
                    title: "Ujian Aktif",
                    value: "\(viewModel.activeExams)",
                    color: .orange,
                    gradient: [.orange, .red]
                )

                StatCard(
                    icon: "chart.bar.fill",
                    title: "Total Sesi",
                    value: "\(viewModel.totalSessions)",
                    color: .blue,
                    gradient: [.blue, .cyan]
                )
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Memuat statistik...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
