//
//  DailyBillBrief.swift
//  Billix
//

import SwiftUI

// MARK: - Daily Bill Brief

struct DailyBillBrief: View {
    let zipCode: String

    @StateObject private var openAIService = OpenAIService.shared
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var authService = AuthService.shared
    @State private var aiBrief: String?
    @State private var isLoading = false
    @State private var isExpanded = false

    private var defaultBrief: String {
        "Check your upcoming bills and stay on track with your budget this week."
    }

    private var displayBrief: String { aiBrief ?? defaultBrief }

    private var briefIcon: String {
        if let weather = weatherService.currentWeather {
            if weather.isHot { return "thermometer.sun.fill" }
            else if weather.isCold { return "thermometer.snowflake" }
        }
        return "newspaper.fill"
    }

    private var briefIconColor: Color {
        if let weather = weatherService.currentWeather {
            if weather.isHot { return HomeTheme.danger }
            else if weather.isCold { return HomeTheme.info }
        }
        return HomeTheme.info
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: HomeTheme.iconSmall))
                    .foregroundColor(HomeTheme.purple)
                Text("AI Daily Brief").sectionHeader()

                Spacer()

                if aiBrief != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 10))
                        Text("Personalized")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(HomeTheme.purple)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(HomeTheme.purple.opacity(0.1))
                    .cornerRadius(6)
                }
            }

            Button {
                haptic()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: briefIcon)
                                .font(.system(size: HomeTheme.iconSmall))
                                .foregroundColor(briefIconColor)
                            Text("Your Daily Update")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(HomeTheme.primaryText)

                            Spacer()

                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(HomeTheme.accent)
                        }

                        if isLoading {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Generating personalized brief...")
                                    .font(.system(size: 13))
                                    .foregroundColor(HomeTheme.secondaryText)
                            }
                        } else {
                            Text(displayBrief)
                                .font(.system(size: 14))
                                .foregroundColor(HomeTheme.secondaryText)
                                .lineSpacing(4)
                                .lineLimit(isExpanded ? nil : 2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(HomeTheme.cardPadding)

                    if isExpanded {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()

                            HStack(spacing: 10) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(HomeTheme.accent)
                                    .frame(width: 24, height: 24)
                                    .background(HomeTheme.accentLight)
                                    .cornerRadius(6)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Location Context")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(HomeTheme.secondaryText)
                                    Text(zipCode.isEmpty ? "Add ZIP code for personalized insights" : "Based on \(zipCode) rates and trends")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(HomeTheme.primaryText)
                                }
                            }

                            if let weather = weatherService.currentWeather {
                                HStack(spacing: 10) {
                                    Image(systemName: weatherService.getWeatherIcon())
                                        .font(.system(size: 12))
                                        .foregroundColor(HomeTheme.info)
                                        .frame(width: 24, height: 24)
                                        .background(HomeTheme.info.opacity(0.12))
                                        .cornerRadius(6)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Weather Factor")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(HomeTheme.secondaryText)
                                        Text("\(weather.temperatureInt)°F \(weather.condition) in \(weather.cityName)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(HomeTheme.primaryText)
                                    }
                                }
                            }

                            Button {
                                haptic()
                                Task { await generateBrief() }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Refresh Brief")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(HomeTheme.accent)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, HomeTheme.cardPadding)
                        .padding(.bottom, HomeTheme.cardPadding)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .background(
                    LinearGradient(
                        colors: [HomeTheme.purple.opacity(0.08), HomeTheme.info.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(HomeTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: HomeTheme.cornerRadius)
                        .stroke(HomeTheme.purple.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, HomeTheme.horizontalPadding)
        .task {
            await generateBrief()
        }
    }

    private func generateBrief() async {
        guard !zipCode.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        let profile = authService.currentUser?.billixProfile
        let city = profile?.city
        let state = profile?.state

        let temperature = weatherService.currentWeather?.temperature
        let weatherCondition = weatherService.currentWeather?.condition

        let billTypes = ["Electric", "Internet", "Gas", "Phone"]
        let upcomingBillName: String? = "Verizon"
        let upcomingBillDays: Int? = 5

        do {
            aiBrief = try await openAIService.generateDailyBrief(
                zipCode: zipCode,
                city: city,
                state: state,
                temperature: temperature,
                weatherCondition: weatherCondition,
                billTypes: billTypes,
                upcomingBillName: upcomingBillName,
                upcomingBillDays: upcomingBillDays
            )
        } catch {
            print("❌ Error: Failed to generate AI brief: \(error)")
        }
    }
}
