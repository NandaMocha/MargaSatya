//
//  EncryptionService.swift
//  SecureExamID
//
//  Handles AES-256 encryption/decryption for exam answers
//  Keys are stored securely in iOS Keychain
//

import Foundation
import CryptoKit
import Security

// MARK: - Encryption Models

/// Metadata about encryption used for an answer
struct EncryptionMetadata: Codable {
    let iv: Data
    let algorithm: String
    let keyVersion: Int
    let timestamp: Date

    init(iv: Data, algorithm: String = "AES-256-GCM", keyVersion: Int = 1) {
        self.iv = iv
        self.algorithm = algorithm
        self.keyVersion = keyVersion
        self.timestamp = Date()
    }
}

/// Encrypted answer with all necessary data for decryption
struct EncryptedAnswer: Codable {
    let questionId: String
    let cipherText: Data
    let metadata: EncryptionMetadata

    var iv: Data { metadata.iv }
    var algorithm: String { metadata.algorithm }
    var keyVersion: Int { metadata.keyVersion }
}

// MARK: - Encryption Service Protocol

protocol EncryptionServiceProtocol {
    /// Encrypt plain text answer
    func encryptAnswer(
        plainText: String,
        forQuestionId questionId: String,
        sessionId: String
    ) throws -> EncryptedAnswer

    /// Decrypt encrypted answer back to plain text
    func decryptAnswer(_ encrypted: EncryptedAnswer) throws -> String

    /// Generate and store encryption key in Keychain (call once per install)
    func ensureEncryptionKeyExists() throws

    /// Remove encryption key from Keychain (for logout/reset)
    func removeEncryptionKey() throws
}

// MARK: - Encryption Errors

enum EncryptionError: LocalizedError {
    case encryptionFailed(String)
    case decryptionFailed(String)
    case keyNotFound
    case keyGenerationFailed
    case keychainError(OSStatus)
    case invalidData
    case unsupportedAlgorithm(String)

    var errorDescription: String? {
        switch self {
        case .encryptionFailed(let reason):
            return "Enkripsi gagal: \(reason)"
        case .decryptionFailed(let reason):
            return "Dekripsi gagal: \(reason)"
        case .keyNotFound:
            return "Kunci enkripsi tidak ditemukan"
        case .keyGenerationFailed:
            return "Gagal membuat kunci enkripsi"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .invalidData:
            return "Data tidak valid"
        case .unsupportedAlgorithm(let algo):
            return "Algoritma tidak didukung: \(algo)"
        }
    }
}

// MARK: - Encryption Service Implementation

final class EncryptionService: EncryptionServiceProtocol {

    // MARK: - Properties

    private let keychainService = "com.margasatya.secureexamid.encryption"
    private let keychainAccount = "master-encryption-key"
    private let keySize = 32 // 256 bits for AES-256

    // MARK: - Public Methods

    /// Encrypt answer text using AES-256-GCM
    func encryptAnswer(
        plainText: String,
        forQuestionId questionId: String,
        sessionId: String
    ) throws -> EncryptedAnswer {
        // Get or create encryption key
        let key = try getOrCreateEncryptionKey()

        // Convert plain text to data
        guard let plainData = plainText.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }

        // Generate random IV (Initialization Vector)
        let iv = try generateRandomData(length: 12) // 96 bits for GCM

        do {
            // Create symmetric key
            let symmetricKey = SymmetricKey(data: key)

            // Create nonce from IV
            let nonce = try AES.GCM.Nonce(data: iv)

            // Additional authenticated data (prevents tampering)
            let aad = "\(sessionId):\(questionId)".data(using: .utf8)!

            // Encrypt using AES-GCM
            let sealedBox = try AES.GCM.seal(
                plainData,
                using: symmetricKey,
                nonce: nonce,
                authenticating: aad
            )

            // Get cipher text and tag combined
            guard let cipherText = sealedBox.combined else {
                throw EncryptionError.encryptionFailed("Failed to get combined data")
            }

            // Create metadata
            let metadata = EncryptionMetadata(
                iv: iv,
                algorithm: "AES-256-GCM",
                keyVersion: 1
            )

            return EncryptedAnswer(
                questionId: questionId,
                cipherText: cipherText,
                metadata: metadata
            )

        } catch let error as CryptoKitError {
            throw EncryptionError.encryptionFailed(error.localizedDescription)
        } catch {
            throw EncryptionError.encryptionFailed(error.localizedDescription)
        }
    }

    /// Decrypt encrypted answer back to plain text
    func decryptAnswer(_ encrypted: EncryptedAnswer) throws -> String {
        // Validate algorithm
        guard encrypted.algorithm == "AES-256-GCM" else {
            throw EncryptionError.unsupportedAlgorithm(encrypted.algorithm)
        }

        // Get encryption key
        let key = try getOrCreateEncryptionKey()

        do {
            // Create symmetric key
            let symmetricKey = SymmetricKey(data: key)

            // Create sealed box from cipher text
            let sealedBox = try AES.GCM.SealedBox(combined: encrypted.cipherText)

            // Decrypt
            let decryptedData = try AES.GCM.open(
                sealedBox,
                using: symmetricKey
            )

            // Convert back to string
            guard let plainText = String(data: decryptedData, encoding: .utf8) else {
                throw EncryptionError.decryptionFailed("Failed to convert data to string")
            }

            return plainText

        } catch let error as CryptoKitError {
            throw EncryptionError.decryptionFailed(error.localizedDescription)
        } catch {
            throw EncryptionError.decryptionFailed(error.localizedDescription)
        }
    }

    /// Ensure encryption key exists in Keychain
    func ensureEncryptionKeyExists() throws {
        _ = try getOrCreateEncryptionKey()
    }

    /// Remove encryption key from Keychain
    func removeEncryptionKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw EncryptionError.keychainError(status)
        }
    }

    // MARK: - Private Methods

    /// Get existing key or create new one
    private func getOrCreateEncryptionKey() throws -> Data {
        // Try to retrieve existing key
        if let existingKey = try? retrieveKeyFromKeychain() {
            return existingKey
        }

        // Generate new key
        let newKey = try generateRandomData(length: keySize)

        // Store in Keychain
        try storeKeyInKeychain(newKey)

        return newKey
    }

    /// Retrieve encryption key from Keychain
    private func retrieveKeyFromKeychain() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw EncryptionError.keyNotFound
            }
            throw EncryptionError.keychainError(status)
        }

        guard let keyData = result as? Data else {
            throw EncryptionError.invalidData
        }

        return keyData
    }

    /// Store encryption key in Keychain
    private func storeKeyInKeychain(_ key: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete any existing key first
        try? removeEncryptionKey()

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }

    /// Generate cryptographically secure random data
    private func generateRandomData(length: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)

        guard status == errSecSuccess else {
            throw EncryptionError.keyGenerationFailed
        }

        return Data(bytes)
    }
}

// MARK: - Mock Encryption Service (for testing)

final class MockEncryptionService: EncryptionServiceProtocol {

    var shouldFailEncryption = false
    var shouldFailDecryption = false

    func encryptAnswer(
        plainText: String,
        forQuestionId questionId: String,
        sessionId: String
    ) throws -> EncryptedAnswer {
        if shouldFailEncryption {
            throw EncryptionError.encryptionFailed("Mock failure")
        }

        // Simple mock: base64 encode
        let data = plainText.data(using: .utf8)!
        let encoded = data.base64EncodedData()

        let metadata = EncryptionMetadata(
            iv: Data(repeating: 0, count: 12),
            algorithm: "MOCK",
            keyVersion: 1
        )

        return EncryptedAnswer(
            questionId: questionId,
            cipherText: encoded,
            metadata: metadata
        )
    }

    func decryptAnswer(_ encrypted: EncryptedAnswer) throws -> String {
        if shouldFailDecryption {
            throw EncryptionError.decryptionFailed("Mock failure")
        }

        // Simple mock: base64 decode
        guard let decoded = Data(base64Encoded: encrypted.cipherText),
              let plainText = String(data: decoded, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed("Mock decode failed")
        }

        return plainText
    }

    func ensureEncryptionKeyExists() throws {
        // Mock: do nothing
    }

    func removeEncryptionKey() throws {
        // Mock: do nothing
    }
}
