//
//  AppConfig.swift
//  MargaSatya
//
//  Application configuration stored in Firestore
//

import Foundation
import FirebaseFirestore

// MARK: - App Config Model

struct AppConfig: Codable, Identifiable {
    @DocumentID var id: String?
    var minAppVersion: String
    var currentAppVersion: String
    var isMaintenance: Bool
    var maintenanceMessage: String?
    var forceUpdate: Bool
    var featureFlags: FeatureFlags
    let createdAt: Date
    var updatedAt: Date

    // MARK: - Additional Settings

    var maxUploadSizeMB: Int
    var sessionTimeoutMinutes: Int
    var allowedDomains: [String]

    // MARK: - Initialization

    init(
        id: String? = "default",
        minAppVersion: String = "2.0.0",
        currentAppVersion: String = "2.0.0",
        isMaintenance: Bool = false,
        maintenanceMessage: String? = nil,
        forceUpdate: Bool = false,
        featureFlags: FeatureFlags = FeatureFlags(),
        maxUploadSizeMB: Int = 10,
        sessionTimeoutMinutes: Int = 1440, // 24 hours
        allowedDomains: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.minAppVersion = minAppVersion
        self.currentAppVersion = currentAppVersion
        self.isMaintenance = isMaintenance
        self.maintenanceMessage = maintenanceMessage
        self.forceUpdate = forceUpdate
        self.featureFlags = featureFlags
        self.maxUploadSizeMB = maxUploadSizeMB
        self.sessionTimeoutMinutes = sessionTimeoutMinutes
        self.allowedDomains = allowedDomains
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    var needsUpdate: Bool {
        return compareVersions(AppConfiguration.Info.version, minAppVersion) < 0
    }

    var isInMaintenanceMode: Bool {
        return isMaintenance
    }

    // MARK: - Methods

    mutating func enableMaintenance(message: String) {
        self.isMaintenance = true
        self.maintenanceMessage = message
        self.updatedAt = Date()
    }

    mutating func disableMaintenance() {
        self.isMaintenance = false
        self.maintenanceMessage = nil
        self.updatedAt = Date()
    }

    mutating func updateVersion(min: String, current: String) {
        self.minAppVersion = min
        self.currentAppVersion = current
        self.updatedAt = Date()
    }

    // MARK: - Private Helpers

    private func compareVersions(_ v1: String, _ v2: String) -> Int {
        let components1 = v1.split(separator: ".").compactMap { Int($0) }
        let components2 = v2.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(components1.count, components2.count) {
            let c1 = i < components1.count ? components1[i] : 0
            let c2 = i < components2.count ? components2[i] : 0

            if c1 < c2 {
                return -1
            } else if c1 > c2 {
                return 1
            }
        }

        return 0
    }
}

// MARK: - Feature Flags

struct FeatureFlags: Codable {
    var googleFormExamsEnabled: Bool
    var inAppExamsEnabled: Bool
    var offlineModeEnabled: Bool
    var adminOverrideEnabled: Bool
    var statisticsEnabled: Bool

    init(
        googleFormExamsEnabled: Bool = true,
        inAppExamsEnabled: Bool = true,
        offlineModeEnabled: Bool = true,
        adminOverrideEnabled: Bool = true,
        statisticsEnabled: Bool = true
    ) {
        self.googleFormExamsEnabled = googleFormExamsEnabled
        self.inAppExamsEnabled = inAppExamsEnabled
        self.offlineModeEnabled = offlineModeEnabled
        self.adminOverrideEnabled = adminOverrideEnabled
        self.statisticsEnabled = statisticsEnabled
    }
}

// MARK: - Default Config

extension AppConfig {
    static func `default`() -> AppConfig {
        return AppConfig(
            id: "default",
            minAppVersion: "2.0.0",
            currentAppVersion: "2.0.0",
            isMaintenance: false,
            allowedDomains: [
                "docs.google.com",
                "forms.google.com",
                "accounts.google.com"
            ]
        )
    }
}
