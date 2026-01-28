import Foundation

/// Example usage of the Explore services
/// This file demonstrates how to use the MarketplaceService and HousingMarketService
/// Can be used for testing and as a reference for ViewModels

// MARK: - Bills Marketplace Examples

func exampleFetchMarketplace() async {
    do {
        // Fetch all marketplace data
        _ = try await MarketplaceService.shared.fetchMarketplaceData()

        // Fetch filtered by ZIP code
        _ = try await MarketplaceService.shared.fetchMarketplaceData(zipPrefix: "941")

        // Fetch filtered by category
        _ = try await MarketplaceService.shared.fetchMarketplaceData(category: "Electric")

        // Fetch with sorting
        _ = try await MarketplaceService.shared.fetchMarketplaceData(sort: "price_asc")

        // Get category statistics
        _ = try await MarketplaceService.shared.getCategoryStats(category: "Electric", zipPrefix: "941")

    } catch {
        // Error handling
    }
}

// MARK: - Housing Market Examples

func exampleFetchHousingMarket() async {
    do {
        // Fetch by ZIP code
        _ = try await HousingMarketService.shared.fetchMarketData(zipCode: "94102")

        // Fetch by city and state
        _ = try await HousingMarketService.shared.fetchMarketData(
            city: "San Francisco",
            state: "CA"
        )

        // Fetch with filters
        _ = try await HousingMarketService.shared.fetchMarketData(
            zipCode: "94102",
            propertyType: "apartment",
            bedrooms: 2
        )

    } catch {
        // Error handling
    }
}

// MARK: - Rent Estimate Examples

func exampleFetchRentEstimate() async {
    do {
        // Estimate by address
        _ = try await HousingMarketService.shared.fetchRentEstimate(
            address: "123 Main St, San Francisco, CA 94102"
        )

    } catch {
        // Error handling
    }
}

// MARK: - Market Trends Examples

func exampleFetchMarketTrends() async {
    do {
        // Fetch 12-month trends
        _ = try await HousingMarketService.shared.fetchMarketTrends(
            zipCode: "94102",
            months: 12
        )

        // Fetch 60-month trends for specific property type
        _ = try await HousingMarketService.shared.fetchMarketTrends(
            zipCode: "94102",
            propertyType: "apartment",
            months: 60
        )

    } catch {
        // Error handling
    }
}

// MARK: - Comparables Examples

func exampleFetchComparables() async {
    do {
        _ = try await HousingMarketService.shared.fetchComparables(zipCode: "94102")

    } catch {
        // Error handling
    }
}

// MARK: - Cache Management Examples

func exampleCacheManagement() async {
    let cacheManager = CacheManager.shared

    // Get cache size
    _ = await cacheManager.getFormattedCacheSize()

    // Clear expired entries
    await cacheManager.clearExpired()

    // Clear all cache
    // await cacheManager.clearAll()
}
