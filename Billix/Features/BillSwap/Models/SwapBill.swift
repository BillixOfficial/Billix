//
//  SwapBill.swift
//  Billix
//
//  Bill model for the BillSwap feature
//

import Foundation

/// Bill status in the swap marketplace
enum SwapBillStatus: String, Codable, CaseIterable {
    case unmatched
    case matched
    case paid

    var displayName: String {
        switch self {
        case .unmatched: return "Unmatched"
        case .matched: return "Matched"
        case .paid: return "Paid"
        }
    }
}

// Note: SwapBillCategory is defined in TrustLadderEnums.swift
// Use categories like .electric, .naturalGas, .water, .internet, .phonePlan, etc.

/// A bill uploaded for swapping
struct SwapBill: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var amount: Decimal
    var dueDate: Date?
    var providerName: String?
    var category: SwapBillCategory?
    var zipCode: String?
    var status: SwapBillStatus
    var imageUrl: String?
    var accountNumber: String?  // Hidden until handshake fee is paid
    var guestPayLink: String?   // URL for guest payment on provider website
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amount
        case dueDate = "due_date"
        case providerName = "provider_name"
        case category
        case zipCode = "zip_code"
        case status
        case imageUrl = "image_url"
        case accountNumber = "account_number"
        case guestPayLink = "guest_pay_link"
        case createdAt = "created_at"
    }

    /// Check if this bill can be matched with another
    func canMatchWith(_ other: SwapBill) -> Bool {
        // Must be different users
        guard userId != other.userId else { return false }

        // Both must be unmatched
        guard status == .unmatched && other.status == .unmatched else { return false }

        // Amounts must be within 10% of each other
        let lowerBound = amount * Decimal(0.9)
        let upperBound = amount * Decimal(1.1)
        return other.amount >= lowerBound && other.amount <= upperBound
    }

    /// Formatted amount string
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }

    /// Formatted due date string
    var formattedDueDate: String? {
        guard let dueDate = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }

    /// Days until due (negative if past due)
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return components.day
    }

    /// Whether the bill is past due
    var isPastDue: Bool {
        guard let days = daysUntilDue else { return false }
        return days < 0
    }

    /// Get city name from zip code (basic mapping for common areas)
    /// In production, this would use a proper geocoding service
    var cityFromZip: String? {
        guard let zip = zipCode, !zip.isEmpty else { return nil }

        // Basic zip code to city mapping for major areas
        // This is a simplified version - production would use CoreLocation or a geocoding API
        let zipPrefix = String(zip.prefix(3))

        let cityMap: [String: String] = [
            // Michigan
            "481": "Detroit, MI",
            "482": "Detroit, MI",
            "483": "Royal Oak, MI",
            "484": "Flint, MI",
            "485": "Flint, MI",
            "486": "Saginaw, MI",
            "487": "Bay City, MI",
            "488": "Lansing, MI",
            "489": "Lansing, MI",
            "490": "Kalamazoo, MI",
            "491": "Kalamazoo, MI",
            "492": "Jackson, MI",
            "493": "Grand Rapids, MI",
            "494": "Grand Rapids, MI",
            "495": "Grand Rapids, MI",
            "496": "Traverse City, MI",
            "497": "Gaylord, MI",
            "498": "Iron Mountain, MI",
            "499": "Iron Mountain, MI",

            // Texas
            "750": "Dallas, TX",
            "751": "Dallas, TX",
            "752": "Dallas, TX",
            "753": "Dallas, TX",
            "754": "Greenville, TX",
            "755": "Texarkana, TX",
            "756": "Longview, TX",
            "757": "Tyler, TX",
            "758": "Palestine, TX",
            "759": "Lufkin, TX",
            "760": "Fort Worth, TX",
            "761": "Fort Worth, TX",
            "762": "Denton, TX",
            "763": "Wichita Falls, TX",
            "764": "Fort Worth, TX",
            "765": "Waco, TX",
            "766": "Waco, TX",
            "767": "Waco, TX",
            "768": "Abilene, TX",
            "769": "San Angelo, TX",
            "770": "Houston, TX",
            "771": "Houston, TX",
            "772": "Houston, TX",
            "773": "Conroe, TX",
            "774": "Pasadena, TX",
            "775": "Galveston, TX",
            "776": "Beaumont, TX",
            "777": "Beaumont, TX",
            "778": "Bryan, TX",
            "779": "Victoria, TX",
            "780": "San Antonio, TX",
            "781": "San Antonio, TX",
            "782": "San Antonio, TX",
            "783": "Corpus Christi, TX",
            "784": "Corpus Christi, TX",
            "785": "McAllen, TX",
            "786": "Austin, TX",
            "787": "Austin, TX",
            "788": "Del Rio, TX",
            "789": "Midland, TX",
            "790": "Amarillo, TX",
            "791": "Amarillo, TX",
            "792": "Childress, TX",
            "793": "Lubbock, TX",
            "794": "Lubbock, TX",
            "795": "Abilene, TX",
            "796": "Abilene, TX",
            "797": "Midland, TX",
            "798": "El Paso, TX",
            "799": "El Paso, TX",

            // California
            "900": "Los Angeles, CA",
            "901": "Los Angeles, CA",
            "902": "Inglewood, CA",
            "903": "Inglewood, CA",
            "904": "Santa Monica, CA",
            "905": "Torrance, CA",
            "906": "Torrance, CA",
            "907": "Long Beach, CA",
            "908": "Long Beach, CA",
            "910": "Pasadena, CA",
            "911": "Pasadena, CA",
            "912": "Glendale, CA",
            "913": "Van Nuys, CA",
            "914": "Van Nuys, CA",
            "915": "Burbank, CA",
            "916": "North Hollywood, CA",
            "917": "Northridge, CA",
            "918": "Northridge, CA",
            "919": "San Fernando, CA",
            "920": "San Diego, CA",
            "921": "San Diego, CA",
            "922": "Palm Springs, CA",
            "923": "San Bernardino, CA",
            "924": "San Bernardino, CA",
            "925": "Riverside, CA",
            "926": "Santa Ana, CA",
            "927": "Santa Ana, CA",
            "928": "Anaheim, CA",
            "930": "Ventura, CA",
            "931": "Santa Barbara, CA",
            "932": "Bakersfield, CA",
            "933": "Bakersfield, CA",
            "934": "Santa Barbara, CA",
            "935": "Mojave, CA",
            "936": "Fresno, CA",
            "937": "Fresno, CA",
            "938": "Fresno, CA",
            "939": "Salinas, CA",
            "940": "San Francisco, CA",
            "941": "San Francisco, CA",
            "942": "Sacramento, CA",
            "943": "Palo Alto, CA",
            "944": "San Mateo, CA",
            "945": "Oakland, CA",
            "946": "Oakland, CA",
            "947": "Berkeley, CA",
            "948": "Richmond, CA",
            "949": "San Rafael, CA",
            "950": "San Jose, CA",
            "951": "San Jose, CA",
            "952": "Stockton, CA",
            "953": "Stockton, CA",
            "954": "Santa Rosa, CA",
            "955": "Eureka, CA",
            "956": "Sacramento, CA",
            "957": "Sacramento, CA",
            "958": "Sacramento, CA",
            "959": "Marysville, CA",
            "960": "Redding, CA",
            "961": "Reno, NV",

            // New York
            "100": "New York, NY",
            "101": "New York, NY",
            "102": "New York, NY",
            "103": "Staten Island, NY",
            "104": "Bronx, NY",
            "105": "Westchester, NY",
            "106": "White Plains, NY",
            "107": "Yonkers, NY",
            "108": "New Rochelle, NY",
            "109": "Suffern, NY",
            "110": "Queens, NY",
            "111": "Long Island City, NY",
            "112": "Brooklyn, NY",
            "113": "Flushing, NY",
            "114": "Jamaica, NY",
            "115": "Hicksville, NY",
            "116": "Far Rockaway, NY",
            "117": "Hicksville, NY",
            "118": "Hicksville, NY",
            "119": "Riverhead, NY",

            // Illinois
            "600": "Chicago, IL",
            "601": "Chicago, IL",
            "602": "Evanston, IL",
            "603": "Oak Park, IL",
            "604": "Arlington Heights, IL",
            "605": "South Suburbs, IL",
            "606": "Chicago, IL",
            "607": "Chicago, IL",
            "608": "Chicago, IL",

            // Georgia
            "300": "Atlanta, GA",
            "301": "Atlanta, GA",
            "302": "Atlanta, GA",
            "303": "Atlanta, GA",

            // Florida
            "320": "Jacksonville, FL",
            "321": "Daytona Beach, FL",
            "322": "Gainesville, FL",
            "323": "Tallahassee, FL",
            "324": "Panama City, FL",
            "325": "Pensacola, FL",
            "326": "Gainesville, FL",
            "327": "Orlando, FL",
            "328": "Orlando, FL",
            "329": "Melbourne, FL",
            "330": "Miami, FL",
            "331": "Miami, FL",
            "332": "Miami Beach, FL",
            "333": "Fort Lauderdale, FL",
            "334": "West Palm Beach, FL",
            "335": "Tampa, FL",
            "336": "Tampa, FL",
            "337": "St. Petersburg, FL",
            "338": "Lakeland, FL",
            "339": "Fort Myers, FL",
        ]

        if let city = cityMap[zipPrefix] {
            return city
        }

        // Fallback: just show the zip code
        return "Zip: \(zip)"
    }
}

// MARK: - Mock Data

extension SwapBill {
    static let mockBills: [SwapBill] = [
        SwapBill(
            id: UUID(),
            userId: UUID(),
            amount: 125.50,
            dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            providerName: "DTE Energy",
            category: .electric,
            zipCode: "48201",
            status: .unmatched,
            imageUrl: nil,
            accountNumber: "****4521",
            guestPayLink: "https://newlook.dteenergy.com/wps/wcm/connect/dte-web/quicklinks/pay-your-bill",
            createdAt: Date()
        ),
        SwapBill(
            id: UUID(),
            userId: UUID(),
            amount: 89.99,
            dueDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
            providerName: "Comcast",
            category: .internet,
            zipCode: "48201",
            status: .unmatched,
            imageUrl: nil,
            accountNumber: "****7892",
            guestPayLink: "https://www.xfinity.com/pay-bill",
            createdAt: Date()
        ),
        SwapBill(
            id: UUID(),
            userId: UUID(),
            amount: 45.00,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            providerName: "Great Lakes Water",
            category: .water,
            zipCode: "48201",
            status: .unmatched,
            imageUrl: nil,
            accountNumber: "****1234",
            guestPayLink: nil,
            createdAt: Date()
        )
    ]
}
