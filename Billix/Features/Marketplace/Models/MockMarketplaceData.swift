//
//  MockMarketplaceData.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import Foundation

/// Mock data for Marketplace development and testing
enum MockMarketplaceData {

    // MARK: - Bill Listings

    static let billListings: [BillListing] = [
        BillListing(
            providerName: "Verizon Fios",
            providerLogoName: "wifi",
            isVerified: true,
            postedDate: Date().addingTimeInterval(-42 * 60), // 42m ago
            zipCode: "07030",
            reliabilityScore: 4.8,
            eligibility: .newCustomer,
            matchScore: 95,
            askPrice: 39.99,
            marketAvgPrice: 89.99,
            fees: 12.00,
            promoDuration: 24,
            grade: .sTier,
            category: .internet,
            specs: DynamicSpecs(
                category: .internet,
                speed: "1 Gig Fiber",
                contractLength: "No Contract",
                equipment: "Own Modem"
            ),
            frictionLevel: .low,
            requirements: ["Autopay", "Mobile Bundle"],
            blueprint: Blueprint(
                strategyType: .retentionCall,
                script: "I'm considering switching to T-Mobile Home Internet because they're offering $50/mo for their 5G plan. I've been a loyal customer for 3 years and would hate to leave, but the pricing difference is significant...",
                dependencies: ["AT&T Mobile Bundle"],
                pointsCost: 50,
                isVerified: true,
                successRate: 0.88,
                totalUses: 142
            ),
            questions: [
                ListingQuestion(question: "Does this stack with student discount?", answer: "Yes", askedDate: Date().addingTimeInterval(-3600)),
                ListingQuestion(question: "Did you have to threaten to cancel?", answer: "No", askedDate: Date().addingTimeInterval(-7200)),
                ListingQuestion(question: "Are you a new customer?", answer: "Yes", askedDate: Date().addingTimeInterval(-10800))
            ],
            sellerHandle: "@SavingsKing_NJ",
            sellerTotalSaved: 4000,
            sellerSuccessRate: 0.88,
            sellerTotalUses: 142,
            isSherpa: false,
            viewingCount: 14,
            unlocksPerHour: 3,
            watchlistCount: 28
        ),
        BillListing(
            providerName: "PSEG",
            providerLogoName: "bolt.fill",
            isVerified: true,
            postedDate: Date().addingTimeInterval(-2 * 3600), // 2h ago
            zipCode: "07302",
            reliabilityScore: 4.5,
            eligibility: .existing,
            matchScore: 82,
            askPrice: 0.11,
            marketAvgPrice: 0.14,
            fees: 0,
            promoDuration: nil,
            grade: .aPlus,
            category: .energy,
            specs: DynamicSpecs(
                category: .energy,
                planType: "Time-of-Use",
                rate: "$0.11/kWh",
                renewablePercent: 30
            ),
            frictionLevel: .medium,
            requirements: ["Budget Billing"],
            blueprint: Blueprint(
                strategyType: .loyaltyOffer,
                script: "I've been reviewing my energy options and noticed the Third Party Supplier rates in my area are lower. Before I switch to [competitor], I wanted to see if there's a loyalty rate available...",
                dependencies: [],
                pointsCost: 35,
                isVerified: true,
                successRate: 0.72,
                totalUses: 89
            ),
            questions: [],
            sellerHandle: "@EnergyNerd",
            sellerTotalSaved: 12500,
            sellerSuccessRate: 0.92,
            sellerTotalUses: 234,
            isSherpa: true,
            viewingCount: 8,
            unlocksPerHour: 1,
            watchlistCount: 15
        ),
        BillListing(
            providerName: "T-Mobile",
            providerLogoName: "iphone",
            isVerified: true,
            postedDate: Date().addingTimeInterval(-5 * 3600), // 5h ago
            zipCode: "07030",
            reliabilityScore: 4.6,
            eligibility: .anyCustomer,
            matchScore: 78,
            askPrice: 25.00,
            marketAvgPrice: 45.00,
            fees: 5.00,
            promoDuration: 12,
            grade: .a,
            category: .mobile,
            specs: DynamicSpecs(
                category: .mobile,
                speed: "Unlimited",
                contractLength: "12 months",
                equipment: nil
            ),
            frictionLevel: .low,
            requirements: ["Autopay", "Paperless"],
            blueprint: Blueprint(
                strategyType: .bundleStack,
                script: "I have Magenta MAX and want to add a line for my family member. I saw the insider discount code for 20% off - can you apply that to my account?",
                dependencies: ["Insider Code"],
                pointsCost: 25,
                isVerified: false,
                successRate: 0.65,
                totalUses: 56
            ),
            questions: [],
            sellerHandle: "@MobileMaven",
            sellerTotalSaved: 2800,
            sellerSuccessRate: 0.78,
            sellerTotalUses: 67,
            isSherpa: false,
            viewingCount: 22,
            unlocksPerHour: 5,
            watchlistCount: 41
        )
    ]

    // MARK: - Clusters

    static let clusters: [Cluster] = [
        Cluster(
            title: "Solar Deals in Jersey City",
            description: "Help unlock a group rate by pledging your budget",
            type: .groupBuy,
            category: .energy,
            status: .forming,
            goalCount: 500,
            currentCount: 150,
            medianContractEnd: Calendar.current.date(byAdding: .month, value: 8, to: Date()),
            medianWillingToPay: 92.00,
            coveredZipCodes: ["07302", "07304", "07305"],
            expiresDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())
        ),
        Cluster(
            title: "Comcast Exodus - Hoboken",
            description: "Coordinate switching to negotiate better rates",
            type: .syndicate,
            category: .internet,
            status: .active,
            goalCount: 200,
            currentCount: 187,
            medianContractEnd: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            medianWillingToPay: 65.00,
            coveredZipCodes: ["07030"],
            expiresDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())
        ),
        Cluster(
            title: "Insurance Bundle - Hudson County",
            description: "Pool home + auto for multi-policy discounts",
            type: .groupBuy,
            category: .insurance,
            status: .goalReached,
            goalCount: 100,
            currentCount: 112,
            medianWillingToPay: 150.00,
            coveredZipCodes: ["07030", "07302", "07306"],
            flashDropOffer: FlashDropOffer(
                providerName: "Geico",
                providerLogoName: "car.fill",
                offerPrice: 125.00,
                originalPrice: 180.00,
                terms: "Bundle home + auto, 15% group discount",
                expiresAt: Calendar.current.date(byAdding: .hour, value: 48, to: Date())!,
                claimCount: 34,
                maxClaims: 112
            )
        )
    ]

    // MARK: - Bounties

    static let bounties: [Bounty] = [
        Bounty(
            title: "PSEG bill under $0.12/kWh in 07030",
            description: "Looking for recent PSEG bills showing rates below $0.12/kWh",
            category: .energy,
            providerName: "PSEG",
            zipCode: "07030",
            requirements: ["PSEG", "07030", "< $0.12/kWh"],
            rewardPoints: 500,
            status: .open,
            expiresDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            claimCount: 3
        ),
        Bounty(
            title: "Optimum retention offer for 500Mbps",
            description: "Need proof of retention department offer for internet upgrade",
            category: .internet,
            providerName: "Optimum",
            requirements: ["Retention offer", "500Mbps+", "Under $60"],
            rewardPoints: 300,
            status: .open,
            expiresDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
            claimCount: 1
        )
    ]

    // MARK: - Scripts

    static let scripts: [NegotiationScript] = [
        NegotiationScript(
            title: "\"I'm moving to Canada\" bluff",
            script: "Hi, I'm calling because I'll be relocating to Canada for work in 3 months. I need to know my options for canceling service. [Wait for retention transfer] Actually, I might be able to stay if the price was more competitive...",
            providerName: "Comcast",
            category: .internet,
            successRate: 0.82,
            totalWins: 234,
            totalUses: 285,
            pointsCost: 75,
            authorHandle: "@ScriptMaster",
            isVerified: true
        ),
        NegotiationScript(
            title: "Student discount stack",
            script: "I'm a graduate student at [University]. I see you offer a student discount. Can this be combined with the current promotion? I also have [competitor] offering $X...",
            providerName: nil,
            category: .internet,
            successRate: 0.68,
            totalWins: 89,
            totalUses: 131,
            pointsCost: 40,
            authorHandle: "@CollegeSaver",
            isVerified: false
        )
    ]

    // MARK: - Services

    static let services: [ServiceListing] = [
        ServiceListing(
            title: "I can find errors in PSEG bills",
            description: "I know tariff rates; I'll check your fees and find overcharges. Saved my neighbor $200 in billing errors.",
            serviceType: .billAudit,
            categories: [.energy],
            providerHandle: "@EnergyNerd",
            isVerifiedHighSaver: true,
            compensation: .tips,
            suggestedAmount: 500,
            rating: 4.9,
            reviewCount: 47,
            completedJobs: 52,
            responseTime: "< 1 hour"
        ),
        ServiceListing(
            title: "Bill Roast - I'll tell you what you're overpaying",
            description: "Send me screenshots of your bills and I'll give you brutal honesty about where you're getting ripped off.",
            serviceType: .billRoast,
            categories: [.internet, .mobile, .energy, .streaming],
            providerHandle: "@BillRoaster",
            isVerifiedHighSaver: false,
            compensation: .free,
            rating: 4.7,
            reviewCount: 128,
            completedJobs: 203,
            responseTime: "< 24 hours"
        )
    ]

    // MARK: - Predictions

    static let predictions: [PredictionMarket] = [
        PredictionMarket(
            question: "Will PSEG rates rise >5% by July?",
            description: "Based on current rate of $0.14/kWh",
            category: .energy,
            providerName: "PSEG",
            currentValue: 0.14,
            targetValue: 0.147,
            targetDate: Calendar.current.date(from: DateComponents(year: 2025, month: 7, day: 1))!,
            yesPercent: 62,
            noPercent: 38,
            totalStaked: 12500
        ),
        PredictionMarket(
            question: "Will Verizon launch $30 5G Home plan?",
            category: .internet,
            providerName: "Verizon",
            targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())!,
            yesPercent: 45,
            noPercent: 55,
            totalStaked: 8200
        )
    ]

    // MARK: - Contract Takeovers

    static let takeovers: [ContractTakeover] = [
        ContractTakeover(
            title: "1GB Internet Contract – 6 months left",
            providerName: "Verizon Fios",
            providerLogoName: "wifi",
            category: .internet,
            monthlyRate: 50.00,
            monthsRemaining: 6,
            etfAvoided: 200,
            sellerIncentive: 50,
            specs: DynamicSpecs(
                category: .internet,
                speed: "1 Gig",
                contractLength: "6 months left",
                equipment: "Router included"
            ),
            sellerHandle: "@MovingOut2025",
            inquiryCount: 5
        )
    ]
}
