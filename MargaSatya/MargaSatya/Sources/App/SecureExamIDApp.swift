//
//  SecureExamIDApp.swift
//  SecureExamID
//
//  Main application entry point
//

import SwiftUI
import FirebaseCore

@main
struct SecureExamIDApp: App {

    // MARK: - Initialization

    init() {
        // Configure Firebase
        FirebaseApp.configure()

        // Initialize encryption keys
        initializeEncryption()

        // Configure app appearance
        configureAppearance()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RoleSelectionView()
                .preferredColorScheme(.dark) // Force dark mode for better glass effect
        }
    }

    // MARK: - Private Helpers

    private func initializeEncryption() {
        do {
            try DIContainer.shared.encryptionService.ensureEncryptionKeyExists()
        } catch {
            print("⚠️ Failed to initialize encryption key: \(error.localizedDescription)")
            // Key will be created on first encryption attempt
        }
    }

    private func configureAppearance() {
        // Configure navigation bar appearance for glass effect
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.1)

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}
