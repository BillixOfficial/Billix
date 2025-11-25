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
    case development  // Uses real API (previously mock)
    case staging      // Uses real API with test data
    case production   // Uses real API with production data

    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

/// Factory for creating bill upload service instances
/// All environments now use the real API at billixapp.com
class BillUploadServiceFactory {

    /// Production API URL
    private static let productionURL = "https://billixapp.com/api/v1"

    /// Create a bill upload service based on current environment
    /// - Returns: Real service for all environments
    static func create() -> BillUploadServiceProtocol {
        switch AppEnvironment.current {
        case .development:
            // Now using real API instead of mock
            return RealBillUploadService(baseURL: productionURL)

        case .staging:
            // Real API pointing to production server
            return RealBillUploadService(baseURL: productionURL)

        case .production:
            // Real API pointing to production server
            return RealBillUploadService(baseURL: productionURL)
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
