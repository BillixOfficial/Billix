import Foundation

/// Example usage of the Explore services
/// This file demonstrates how to use the MarketplaceService and HousingMarketService
/// Can be used for testing and as a reference for ViewModels

// MARK: - Bills Marketplace Examples

func exampleFetchMarketplace() async {
    do {
        // Fetch all marketplace data
        let allData = try await MarketplaceService.shared.fetchMarketplaceData()
        print("✅ Fetched \(allData.count) marketplace entries")

        // Fetch filtered by ZIP code
        let zipData = try await MarketplaceService.shared.fetchMarketplaceData(zipPrefix: "941")
        print("✅ Fetched \(zipData.count) entries for ZIP 941xx")

        // Fetch filtered by category
        let electricData = try await MarketplaceService.shared.fetchMarketplaceData(category: "Electric")
        print("✅ Fetched \(electricData.count) electric providers")

        // Fetch with sorting
        let sortedData = try await MarketplaceService.shared.fetchMarketplaceData(sort: "price_asc")
        print("✅ Fetched sorted data")

        // Get category statistics
        let stats = try await MarketplaceService.shared.getCategoryStats(category: "Electric", zipPrefix: "941")
        print("✅ Electric stats: \(stats.providerCount) providers, avg $\(Int(stats.overallAverage))")

    } catch {
        print("❌ Error: \(error.localizedDescription)")
    }
}

// MARK: - Housing Market Examples

func exampleFetchHousingMarket() async {
    do {
        // Fetch by ZIP code
        let zipData = try await HousingMarketService.shared.fetchMarketData(zipCode: "94102")
        print("✅ Fetched housing data for ZIP 94102: \(zipData.locationName)")
        print("   Avg rent: \(zipData.formattedRentAverage)")

        // Fetch by city and state
        let cityData = try await HousingMarketService.shared.fetchMarketData(
            city: "San Francisco",
            state: "CA"
        )
        print("✅ Fetched housing data for SF: \(cityData.locationName)")

        // Fetch with filters
        let filteredData = try await HousingMarketService.shared.fetchMarketData(
            zipCode: "94102",
            propertyType: "apartment",
            bedrooms: 2
        )
        print("✅ 2-bed apartments: \(filteredData.formattedRentAverage)")

    } catch {
        print("❌ Error: \(error.localizedDescription)")
    }
}

// MARK: - Rent Estimate Examples

func exampleFetchRentEstimate() async {
    do {
        // Estimate by address
        let estimate = try await HousingMarketService.shared.fetchRentEstimate(
            address: "123 Main St, San Francisco, CA 94102"
        )
        print("✅ Rent estimate: \(estimate.formattedEstimate)")
        print("   Range: \(estimate.formattedRange)")
        print("   Comparables: \(estimate.comparables?.count ?? 0)")

    } catch {
        print("❌ Error: \(error.localizedDescription)")
    }
}

// MARK: - Market Trends Examples

func exampleFetchMarketTrends() async {
    do {
        // Fetch 12-month trends
        let trends = try await HousingMarketService.shared.fetchMarketTrends(
            zipCode: "94102",
            months: 12
        )
        print("✅ Fetched \(trends.trends.count) months of trend data")

        // Fetch 60-month trends for specific property type
        let longTrends = try await HousingMarketService.shared.fetchMarketTrends(
            zipCode: "94102",
            propertyType: "apartment",
            months: 60
        )
        print("✅ Fetched \(longTrends.trends.count) months of apartment trends")

    } catch {
        print("❌ Error: \(error.localizedDescription)")
    }
}

// MARK: - Comparables Examples

func exampleFetchComparables() async {
    do {
        let comparables = try await HousingMarketService.shared.fetchComparables(zipCode: "94102")
        print("✅ Fetched \(comparables.count) comparable properties")

        for comp in comparables.prefix(3) {
            print("   - \(comp.address): \(comp.formattedRent ?? "N/A")")
        }

    } catch {
        print("❌ Error: \(error.localizedDescription)")
    }
}

// MARK: - Cache Management Examples

func exampleCacheManagement() async {
    let cacheManager = CacheManager.shared

    // Get cache size
    let size = await cacheManager.getFormattedCacheSize()
    print("📦 Current cache size: \(size)")

    // Clear expired entries
    await cacheManager.clearExpired()
    print("🧹 Cleared expired cache entries")

    // Clear all cache
    // await cacheManager.clearAll()
    // print("🗑️ Cleared all cache")
}
