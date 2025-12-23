//
//  LocationRow.swift
//  Billix
//
//  Created by Claude Code
//  Row component for displaying individual location in the map view
//

import SwiftUI

struct LocationRow: View {
    let location: SeasonLocation
    let progress: UserSeasonProgress?
    let onTap: () -> Void

    private var stars: Int {
        progress?.starsEarned ?? 0
    }

    private var isCompleted: Bool {
        progress?.isCompleted ?? false
    }

    private var difficultyColor: Color {
        switch location.difficulty.lowercased() {
        case "easy":
            return .green
        case "moderate":
            return .orange
        case "hard":
            return .red
        default:
            return .gray
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Left: Location number badge
                ZStack {
                    Circle()
                        .fill(
                            isCompleted
                                ? LinearGradient(
                                    colors: [Color.billixMoneyGreen, Color.billixMoneyGreen.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.billixMediumGreen.opacity(0.3), Color.billixMediumGreen.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 48, height: 48)

                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(location.locationNumber)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.billixDarkGreen)
                    }
                }
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

                // Middle: Location info
                VStack(alignment: .leading, spacing: 6) {
                    // Location name
                    Text(location.locationName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.billixDarkGreen)
                        .lineLimit(1)

                    // Subject + difficulty
                    HStack(spacing: 8) {
                        Text(location.subject)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                            .lineLimit(1)

                        Circle()
                            .fill(Color.billixMediumGreen.opacity(0.3))
                            .frame(width: 3, height: 3)

                        HStack(spacing: 3) {
                            Circle()
                                .fill(difficultyColor)
                                .frame(width: 6, height: 6)

                            Text(location.difficulty.capitalized)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(difficultyColor)
                        }
                    }

                    // Stars (if completed)
                    if isCompleted {
                        HStack(spacing: 3) {
                            ForEach(0..<3) { index in
                                Image(systemName: index < stars ? "star.fill" : "star")
                                    .font(.system(size: 11))
                                    .foregroundColor(index < stars ? .billixArcadeGold : .gray.opacity(0.3))
                            }

                            if let points = progress?.pointsEarned {
                                Text("•")
                                    .font(.system(size: 10))
                                    .foregroundColor(.billixMediumGreen)
                                    .padding(.horizontal, 2)

                                Text("\(points) pts")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.billixDarkGreen)
                            }
                        }
                    } else {
                        Text("Not played yet")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray.opacity(0.6))
                            .italic()
                    }
                }

                Spacer()

                // Right: Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.billixMediumGreen.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Location Row") {
    VStack(spacing: 12) {
        // Not played
        LocationRow(
            location: SeasonLocation(
                id: UUID(),
                seasonPartId: UUID(),
                locationNumber: 1,
                subject: "Manhattan Prices",
                locationName: "Manhattan, NY",
                category: "urban",
                difficulty: "hard",
                locationData: LocationDataJSON(
                    landmarkName: "Empire State Building",
                    coordinates: CoordinateData(lat: 40.7484, lng: -73.9857),
                    landmark: CoordinateData(lat: 40.7484, lng: -73.9857),
                    mapRegion: MapRegionDataJSON(pitch: 60, heading: 0, altitude: 1500),
                    decoyLocations: []
                ),
                priceData: PriceDataJSON(questions: []),
                createdAt: Date()
            ),
            progress: nil,
            onTap: {}
        )
        .padding(.horizontal, 20)

        // Completed with 3 stars
        LocationRow(
            location: SeasonLocation(
                id: UUID(),
                seasonPartId: UUID(),
                locationNumber: 2,
                subject: "San Antonio Prices",
                locationName: "San Antonio, TX",
                category: "urban",
                difficulty: "moderate",
                locationData: LocationDataJSON(
                    landmarkName: "The Alamo",
                    coordinates: CoordinateData(lat: 29.4252, lng: -98.4861),
                    landmark: CoordinateData(lat: 29.4252, lng: -98.4861),
                    mapRegion: MapRegionDataJSON(pitch: 60, heading: 0, altitude: 1500),
                    decoyLocations: []
                ),
                priceData: PriceDataJSON(questions: []),
                createdAt: Date()
            ),
            progress: UserSeasonProgress(
                id: UUID(),
                userId: UUID(),
                seasonId: UUID(),
                partId: UUID(),
                locationId: UUID(),
                isCompleted: true,
                starsEarned: 3,
                pointsEarned: 450,
                bestCombo: 6,
                finalHealth: 3,
                accuracyPercent: 90,
                landmarksCorrect: 1,
                landmarksAttempted: 1,
                pricesCorrect: 2,
                pricesAttempted: 2,
                firstPlayedAt: Date(),
                completedAt: Date(),
                lastPlayedAt: Date()
            ),
            onTap: {}
        )
        .padding(.horizontal, 20)

        // Completed with 1 star
        LocationRow(
            location: SeasonLocation(
                id: UUID(),
                seasonPartId: UUID(),
                locationNumber: 3,
                subject: "Honolulu Prices",
                locationName: "Honolulu, HI",
                category: "island",
                difficulty: "easy",
                locationData: LocationDataJSON(
                    landmarkName: "Diamond Head",
                    coordinates: CoordinateData(lat: 21.3099, lng: -157.8581),
                    landmark: CoordinateData(lat: 21.3099, lng: -157.8581),
                    mapRegion: MapRegionDataJSON(pitch: 60, heading: 0, altitude: 1500),
                    decoyLocations: []
                ),
                priceData: PriceDataJSON(questions: []),
                createdAt: Date()
            ),
            progress: UserSeasonProgress(
                id: UUID(),
                userId: UUID(),
                seasonId: UUID(),
                partId: UUID(),
                locationId: UUID(),
                isCompleted: true,
                starsEarned: 1,
                pointsEarned: 120,
                bestCombo: 2,
                finalHealth: 1,
                accuracyPercent: 50,
                landmarksCorrect: 1,
                landmarksAttempted: 1,
                pricesCorrect: 1,
                pricesAttempted: 2,
                firstPlayedAt: Date(),
                completedAt: Date(),
                lastPlayedAt: Date()
            ),
            onTap: {}
        )
        .padding(.horizontal, 20)
    }
    .background(Color.billixLightGreen)
}
