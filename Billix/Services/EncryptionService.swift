//
//  EncryptionService.swift
//  Billix
//
//  Created by Claude Code on 2/5/26.
//  AES-256 encryption for local chat message storage
//

import Foundation
import CryptoKit
import Security

/// Service for encrypting/decrypting sensitive local data (chat messages)
/// Uses AES-256-GCM with a key stored in Keychain
actor EncryptionService {
    static let shared = EncryptionService()

    private let keychainService = "com.billix.encryption"
    private let keychainAccount = "chatEncryptionKey"

    private init() {}

    // MARK: - Public API

    /// Encrypts data using AES-256-GCM
    func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.seal(data, using: key)

        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        return combined
    }

    /// Decrypts data that was encrypted with encrypt()
    func decrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // MARK: - Key Management

    private func getOrCreateKey() throws -> SymmetricKey {
        // Try to load existing key from Keychain
        if let existingKeyData = loadKeyFromKeychain() {
            return SymmetricKey(data: existingKeyData)
        }

        // Generate new key and save to Keychain
        let newKey = SymmetricKey(size: .bits256)
        try saveKeyToKeychain(newKey)
        return newKey
    }

    private func loadKeyFromKeychain() -> Data? {
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
            return nil
        }

        return result as? Data
    }

    private func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete existing key if present
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }

    // MARK: - Errors

    enum EncryptionError: Error, LocalizedError {
        case encryptionFailed
        case decryptionFailed
        case keychainError(OSStatus)

        var errorDescription: String? {
            switch self {
            case .encryptionFailed:
                return "Failed to encrypt data"
            case .decryptionFailed:
                return "Failed to decrypt data"
            case .keychainError(let status):
                return "Keychain error: \(status)"
            }
        }
    }
}
