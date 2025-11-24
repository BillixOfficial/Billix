//
//  BillUploadServiceFactory.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation

/// Application environment configuration
/// Controls which service implementation to use
enum AppEnvironment {
    case development  // Uses mock data
    case staging      // Uses real API with test data
    case production   // Uses real API with production data

    static var current: AppEnvironment {
        #if DEBUG
        // Change this line to .staging when testing real API
        return .development
        #else
        return .production
        #endif
    }
}

/// Factory for creating bill upload service instances
/// Automatically selects mock or real implementation based on environment
class BillUploadServiceFactory {

    /// Create a bill upload service based on current environment
    /// - Returns: Mock service in development, real service in staging/production
    static func create() -> BillUploadServiceProtocol {
        switch AppEnvironment.current {
        case .development:
            // Mock service with 2 second delay for realistic testing
            return MockBillUploadService(mockDelay: 2.0, shouldSucceed: true)

        case .staging:
            // Real API pointing to staging server
            return RealBillUploadService(baseURL: "https://staging-api.billixapp.com/v1")

        case .production:
            // Real API pointing to production server
            return RealBillUploadService(baseURL: "https://api.billixapp.com/v1")
        }
    }

    /// Create a mock service for testing or previews
    /// - Parameters:
    ///   - mockDelay: Network delay simulation in seconds
    ///   - shouldSucceed: Whether operations should succeed or fail
    /// - Returns: Mock service with specified configuration
    static func createMock(mockDelay: TimeInterval = 1.0, shouldSucceed: Bool = true) -> BillUploadServiceProtocol {
        return MockBillUploadService(mockDelay: mockDelay, shouldSucceed: shouldSucceed)
    }
}
