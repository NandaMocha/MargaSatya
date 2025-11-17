//
//  AdminDashboardView.swift
//  SecureExamID
//
//  Admin dashboard with system statistics and monitoring
//

import SwiftUI

struct AdminDashboardView: View {

    // MARK: - Properties

    let user: User
    @StateObject private var viewModel: AdminDashboardViewModel
    @State private var selectedTeacher: User?

    // MARK: - Initialization

    init(user: User, viewModel: AdminDashboardViewModel) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Summary Stats
                        if viewModel.isLoading && !viewModel.hasSummary {
                            loadingView
                        } else if viewModel.hasSummary {
                            summarySection
                            teachersSection
                        } else {
                            emptyStateView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task { await viewModel.refresh() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }

                        Divider()

                        Button(role: .destructive) {
                            // Logout action
                        } label: {
                            Label("Keluar", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
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
            .sheet(item: $selectedTeacher) { teacher in
                NavigationStack {
                    TeacherStatsView(
                        teacher: teacher,
                        viewModel: DIContainer.shared.makeTeacherStatsViewModel(teacherId: teacher.id ?? "")
                    )
                }
            }
            .task {
                await viewModel.loadDashboard()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.purple.opacity(0.6), .pink.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "crown.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }

            Text("Selamat Datang!")
                .font(.title3)
                .foregroundColor(.secondary)

            Text(user.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Label("Administrator", systemImage: "key.fill")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
        }
        .padding(.vertical)
    }

    private var summarySection: some View {
        VStack(spacing: 16) {
            Text("Ringkasan Sistem")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    icon: "person.2.fill",
                    title: "Total Guru",
                    value: "\(viewModel.totalTeachers)",
                    color: .blue,
                    gradient: [.blue, .cyan]
                )

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
                    title: "Ujian Berjalan",
                    value: "\(viewModel.runningExams)",
                    color: .orange,
                    gradient: [.orange, .red]
                )
            }

            // Today's Sessions
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sesi Hari Ini")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("\(viewModel.sessionsToday) sesi")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    private var teachersSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Daftar Guru")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(viewModel.teachers.count) guru")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.teachers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("Belum ada guru terdaftar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.teachers) { teacher in
                        TeacherRow(teacher: teacher) {
                            selectedTeacher = teacher
                        }
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Memuat data dashboard...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Tidak ada data")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Stat Card

struct AdminStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let gradient: [Color]

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Teacher Row

struct TeacherRow: View {
    let teacher: User
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(teacher.name.prefix(1).uppercased())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(teacher.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(teacher.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}
