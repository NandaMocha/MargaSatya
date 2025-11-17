//
//  TeacherHomeView.swift
//  SecureExamID
//
//  Teacher dashboard with navigation to student and exam management
//

import SwiftUI

struct TeacherHomeView: View {

    // MARK: - Properties

    let user: User

    @State private var showStudentList = false
    @State private var showExamList = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Menu Grid
                        menuGrid

                        // Stats Section (placeholder)
                        statsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Portal Guru")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            // Profile action
                        } label: {
                            Label("Profil Saya", systemImage: "person.circle")
                        }

                        Button {
                            // Settings action
                        } label: {
                            Label("Pengaturan", systemImage: "gear")
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
            .navigationDestination(isPresented: $showStudentList) {
                StudentListView(
                    user: user,
                    viewModel: DIContainer.shared.makeStudentListViewModel(teacherId: user.id ?? "")
                )
            }
            .navigationDestination(isPresented: $showExamList) {
                ExamListPlaceholderView()
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 12) {
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
                    Text(user.name.prefix(1).uppercased())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

            Text("Selamat Datang!")
                .font(.title3)
                .foregroundColor(.secondary)

            Text(user.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Label("Guru", systemImage: "briefcase.fill")
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

    private var menuGrid: some View {
        VStack(spacing: 16) {
            Text("Menu Utama")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MenuCard(
                    title: "Data Siswa",
                    subtitle: "Kelola siswa",
                    icon: "person.3.fill",
                    gradient: [.blue, .cyan],
                    action: {
                        showStudentList = true
                    }
                )

                MenuCard(
                    title: "Data Ujian",
                    subtitle: "Kelola ujian",
                    icon: "doc.text.fill",
                    gradient: [.purple, .pink],
                    isDisabled: true,
                    action: {
                        showExamList = true
                    }
                )

                MenuCard(
                    title: "Hasil Ujian",
                    subtitle: "Lihat hasil",
                    icon: "chart.bar.fill",
                    gradient: [.orange, .red],
                    isDisabled: true,
                    action: {
                        // To be implemented in Fase 5
                    }
                )

                MenuCard(
                    title: "Laporan",
                    subtitle: "Statistik",
                    icon: "doc.chart.fill",
                    gradient: [.green, .mint],
                    isDisabled: true,
                    action: {
                        // To be implemented in Fase 5
                    }
                )
            }
        }
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            Text("Ringkasan")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                StatCard(
                    title: "Total Siswa",
                    value: "-",
                    icon: "person.3.fill",
                    color: .blue
                )

                StatCard(
                    title: "Ujian Aktif",
                    value: "-",
                    icon: "doc.text.fill",
                    color: .purple
                )
            }
        }
    }
}

// MARK: - Menu Card

struct MenuCard: View {

    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if isDisabled {
                    Text("Segera Hadir")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.orange.opacity(0.2))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .disabled(isDisabled)
    }
}

// MARK: - Stat Card

struct StatCard: View {

    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Placeholder Views

struct ExamListPlaceholderView: View {
    var body: some View {
        ZStack {
            GlassBackground()

            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.secondary)

                Text("Manajemen Ujian")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Fitur ini akan tersedia di Fase 5")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Data Ujian")
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
