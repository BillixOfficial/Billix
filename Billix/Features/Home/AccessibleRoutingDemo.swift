//
//  AccessibleRoutingDemo.swift
//  Billix
//
//  Accessibility-First Pedestrian Routing Demo
//  Shows baseline vs accessible routes with warnings and tooltips
//

import SwiftUI
import MapKit

// MARK: - Data Models

typealias Coord = [Double] // [lon, lat]

struct RouteEdge: Identifiable, Codable {
    let id: Int
    let geometry: RouteGeometry
    let lenM: Double
    let timeS: Double
    let tags: EdgeTags
    var lastConfirmed: String?
    var isCrossing: Bool?
    var isEntrance: Bool?
    var onlyStairs: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "edge_id"
        case geometry, tags
        case lenM = "len_m"
        case timeS = "time_s"
        case lastConfirmed = "last_confirmed"
        case isCrossing = "is_crossing"
        case isEntrance = "is_entrance"
        case onlyStairs = "only_stairs"
    }
}

struct RouteGeometry: Codable {
    let type: String
    let coordinates: [[Double]]
}

struct EdgeTags: Codable {
    var stairs: Bool?
    var curbRamp: String? // "true", "false", "unknown"
    var surface: String?
    var incline: Double?
    var elevator: Bool?

    enum CodingKeys: String, CodingKey {
        case stairs, surface, incline, elevator
        case curbRamp = "curb_ramp"
    }
}

struct RouteStep: Identifiable, Codable {
    let id = UUID()
    let text: String
    let distanceM: Double

    enum CodingKeys: String, CodingKey {
        case text
        case distanceM = "distance_m"
    }
}

struct RouteWarning: Codable {
    let type: String
    let nodeId: Int

    enum CodingKeys: String, CodingKey {
        case type
        case nodeId = "node_id"
    }
}

struct RouteProvenance: Codable {
    let osmSnapshot: String
    var engineVersion: String?

    enum CodingKeys: String, CodingKey {
        case osmSnapshot = "osm_snapshot"
        case engineVersion = "engine_version"
    }
}

struct RouteSummary: Codable {
    let distanceKm: Double
    let timeMin: Double
    let warnings: [RouteWarning]
    let provenance: RouteProvenance

    enum CodingKeys: String, CodingKey {
        case distanceKm = "distance_km"
        case timeMin = "time_min"
        case warnings, provenance
    }
}

struct RoutePayload: Codable {
    let routeId: String
    let edges: [RouteEdge]
    let steps: [RouteStep]
    let summary: RouteSummary

    enum CodingKeys: String, CodingKey {
        case routeId = "route_id"
        case edges, steps, summary
    }
}

struct GnssFix {
    let lat: Double
    let lon: Double
    let fixTime: String
    let fixAccuracyM: Double
    var snapped: Bool?
}

// MARK: - Mock Data

struct MockRouteData {
    static let baseline = RoutePayload(
        routeId: "r_demo_baseline",
        edges: [
            RouteEdge(
                id: 1001,
                geometry: RouteGeometry(type: "LineString", coordinates: [[-84.3963, 33.7756], [-84.3959, 33.7758], [-84.3955, 33.7761]]),
                lenM: 140, timeS: 120,
                tags: EdgeTags(stairs: false, curbRamp: "true", surface: "asphalt", incline: 0.02, elevator: false),
                lastConfirmed: "2025-07-01"
            ),
            RouteEdge(
                id: 1002,
                geometry: RouteGeometry(type: "LineString", coordinates: [[-84.3955, 33.7761], [-84.3952, 33.7764]]),
                lenM: 60, timeS: 55,
                tags: EdgeTags(stairs: true, curbRamp: nil, surface: "concrete", incline: 0.03, elevator: nil),
                isCrossing: true
            ),
            RouteEdge(
                id: 1003,
                geometry: RouteGeometry(type: "LineString", coordinates: [[-84.3952, 33.7764], [-84.3948, 33.7766]]),
                lenM: 80, timeS: 70,
                tags: EdgeTags(stairs: nil, curbRamp: "unknown", surface: "asphalt", incline: 0.02, elevator: nil),
                isCrossing: true
            )
        ],
        steps: [
            RouteStep(text: "Head east on Fern St", distanceM: 120),
            RouteStep(text: "Cross mid-block stairs", distanceM: 60),
            RouteStep(text: "Continue toward Peachtree Ave", distanceM: 80)
        ],
        summary: RouteSummary(
            distanceKm: 1.28, timeMin: 14.1,
            warnings: [RouteWarning(type: "unknown_curb_ramp", nodeId: 5511)],
            provenance: RouteProvenance(osmSnapshot: "2025-10-10", engineVersion: "0.2.1")
        )
    )

    static let accessible = RoutePayload(
        routeId: "r_demo_accessible",
        edges: [
            RouteEdge(
                id: 2001,
                geometry: RouteGeometry(type: "LineString", coordinates: [[-84.3963, 33.7756], [-84.3960, 33.7759], [-84.3957, 33.7762]]),
                lenM: 160, timeS: 135,
                tags: EdgeTags(stairs: false, curbRamp: "true", surface: "asphalt", incline: 0.02, elevator: false),
                lastConfirmed: "2025-11-10"
            ),
            RouteEdge(
                id: 2002,
                geometry: RouteGeometry(type: "LineString", coordinates: [[-84.3957, 33.7762], [-84.3953, 33.7765], [-84.3950, 33.7766]]),
                lenM: 120, timeS: 110,
                tags: EdgeTags(stairs: false, curbRamp: "true", surface: "concrete", incline: 0.03, elevator: nil),
                lastConfirmed: "2025-11-05", isCrossing: true
            ),
            RouteEdge(
                id: 2003,
                geometry: RouteGeometry(type: "LineString", coordinates: [[-84.3950, 33.7766], [-84.3948, 33.7766]]),
                lenM: 40, timeS: 35,
                tags: EdgeTags(stairs: false, curbRamp: "true", surface: "asphalt", incline: 0.02, elevator: nil)
            )
        ],
        steps: [
            RouteStep(text: "Head east on Fern St", distanceM: 160),
            RouteStep(text: "Use ramp at NE corner", distanceM: 120),
            RouteStep(text: "Continue toward Peachtree Ave", distanceM: 40)
        ],
        summary: RouteSummary(
            distanceKm: 1.39, timeMin: 15.3,
            warnings: [],
            provenance: RouteProvenance(osmSnapshot: "2025-10-10", engineVersion: "0.2.1")
        )
    )
}

// MARK: - Theme

private enum RoutingTheme {
    static let background = Color(hex: "#F5F7FA")
    static let cardBg = Color.white
    static let primary = Color(hex: "#1A365D")
    static let secondary = Color(hex: "#718096")
    static let accent = Color(hex: "#3182CE")
    static let success = Color(hex: "#38A169")
    static let warning = Color(hex: "#DD6B20")
    static let danger = Color(hex: "#E53E3E")
    static let baselineColor = Color.gray.opacity(0.6)
    static let accessibleColor = Color(hex: "#3182CE")
}

// MARK: - Main Demo View

struct AccessibleRoutingDemoView: View {
    @State private var selectedRoute: RouteType = .accessible
    @State private var showTooltip = false
    @State private var selectedEdge: RouteEdge?
    @State private var tooltipPosition: CGPoint = .zero
    @State private var showConfirmDialog = false

    private let gnssFix = GnssFix(
        lat: 33.7756, lon: -84.3963,
        fixTime: "2025-11-30T18:22:15Z",
        fixAccuracyM: 18.0, snapped: true
    )

    enum RouteType: String, CaseIterable {
        case baseline = "Baseline"
        case accessible = "Accessible-first"
    }

    private var currentRoute: RoutePayload {
        selectedRoute == .baseline ? MockRouteData.baseline : MockRouteData.accessible
    }

    private var hasUnknownCurbRamp: Bool {
        currentRoute.summary.warnings.contains { $0.type == "unknown_curb_ramp" }
    }

    private var barrierCount: Int {
        currentRoute.summary.warnings.count + (currentRoute.edges.contains { $0.tags.stairs == true } ? 1 : 0)
    }

    var body: some View {
        ZStack {
            RoutingTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Warning Banner (if applicable)
                if hasUnknownCurbRamp {
                    WarningBannerView(onConfirmTap: { showConfirmDialog = true })
                }

                // Map Section
                RouteMapView(
                    baselineRoute: MockRouteData.baseline,
                    accessibleRoute: MockRouteData.accessible,
                    selectedRoute: selectedRoute,
                    gnssFix: gnssFix,
                    onEdgeTap: { edge, position in
                        selectedEdge = edge
                        tooltipPosition = position
                        showTooltip = true
                    }
                )
                .frame(height: 340)

                // Bottom Panel
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Route Toggle
                        RouteToggleView(selected: $selectedRoute)

                        // Accuracy Chip
                        if gnssFix.fixAccuracyM > 15 {
                            AccuracyChipView(fix: gnssFix)
                        }

                        // Route Summary with barrier count
                        RouteSummaryView(route: currentRoute, barrierCount: barrierCount)

                        // Step List
                        StepListView(
                            steps: currentRoute.steps,
                            edges: currentRoute.edges,
                            onStepTap: { index in
                                if index < currentRoute.edges.count {
                                    selectedEdge = currentRoute.edges[index]
                                    showTooltip = true
                                }
                            }
                        )

                        // Provenance Footer
                        ProvenanceFooterView(provenance: currentRoute.summary.provenance)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .background(RoutingTheme.cardBg)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
            }

            // Tag Tooltip Overlay
            if showTooltip, let edge = selectedEdge {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showTooltip = false }

                TagTooltipView(
                    edge: edge,
                    osmSnapshot: currentRoute.summary.provenance.osmSnapshot,
                    onClose: { showTooltip = false }
                )
            }
        }
        .sheet(isPresented: $showConfirmDialog) {
            ConfirmCurbRampSheet()
                .presentationDetents([.medium])
                .presentationBackground(Color(hex: "#F5F7F6"))
        }
    }
}

// MARK: - Route Map View

struct RouteMapView: View {
    let baselineRoute: RoutePayload
    let accessibleRoute: RoutePayload
    let selectedRoute: AccessibleRoutingDemoView.RouteType
    let gnssFix: GnssFix
    let onEdgeTap: (RouteEdge, CGPoint) -> Void

    // Tighter zoom to show conflict clearly
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.7762, longitude: -84.3955),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    ))

    var body: some View {
        ZStack {
            // Map background
            Map(position: $position, interactionModes: []) {
                ForEach(annotations) { item in
                    Annotation("", coordinate: item.coordinate) {
                        annotationView(for: item)
                    }
                }
            }

            // Route overlay (drawn on top)
            Canvas { context, size in
                // Draw baseline route (thin dashed gray) - draw first so accessible is on top
                drawRoute(context: context, size: size, route: baselineRoute, color: Color.gray, lineWidth: 3, dashed: true)

                // Draw accessible route (thick solid blue)
                drawRoute(context: context, size: size, route: accessibleRoute, color: RoutingTheme.accessibleColor, lineWidth: 7, dashed: false)
            }
            .allowsHitTesting(false)

            // Legend - Bottom left, away from routes
            VStack {
                Spacer()
                HStack {
                    LegendView()
                        .padding(12)
                    Spacer()
                }
            }
            .padding(.bottom, 8)
            .padding(.leading, 8)

            // User location marker - Start point
            VStack {
                Spacer()
                HStack {
                    UserLocationMarker()
                        .padding(.leading, 24)
                        .padding(.bottom, 100)
                    Spacer()
                }
            }

            // Destination marker
            VStack {
                HStack {
                    Spacer()
                    DestinationMarker()
                        .padding(.trailing, 24)
                        .padding(.top, 80)
                }
                Spacer()
            }
        }
    }

    private var annotations: [RouteAnnotation] {
        var items: [RouteAnnotation] = []

        // Add stairs marker on baseline
        if let stairsEdge = baselineRoute.edges.first(where: { $0.tags.stairs == true }) {
            let coord = stairsEdge.geometry.coordinates[0]
            items.append(RouteAnnotation(
                id: "stairs",
                coordinate: CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0]),
                type: .stairs
            ))
        }

        // Add unknown curb ramp marker
        if let unknownRamp = baselineRoute.edges.first(where: { $0.tags.curbRamp == "unknown" }) {
            let coord = unknownRamp.geometry.coordinates[0]
            items.append(RouteAnnotation(
                id: "unknown_ramp",
                coordinate: CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0]),
                type: .unknownRamp
            ))
        }

        // Add confirmed ramp markers on accessible route
        for edge in accessibleRoute.edges where edge.tags.curbRamp == "true" {
            let coord = edge.geometry.coordinates[0]
            items.append(RouteAnnotation(
                id: "ramp_\(edge.id)",
                coordinate: CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0]),
                type: .ramp
            ))
        }

        return items
    }

    private func drawRoute(context: GraphicsContext, size: CGSize, route: RoutePayload, color: Color, lineWidth: CGFloat, dashed: Bool) {
        var path = Path()

        for edge in route.edges {
            let points = edge.geometry.coordinates.map { coord -> CGPoint in
                // Simple projection (not accurate but works for demo)
                let x = (coord[0] + 84.3963) * 60000 + size.width / 2
                let y = (33.7766 - coord[1]) * 60000 + size.height / 2
                return CGPoint(x: x, y: y)
            }

            if let first = points.first {
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
        }

        let style = StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .round,
            lineJoin: .round,
            dash: dashed ? [8, 6] : []
        )
        context.stroke(path, with: .color(color), style: style)
    }

    @ViewBuilder
    private func annotationView(for item: RouteAnnotation) -> some View {
        switch item.type {
        case .stairs:
            ZStack {
                Circle()
                    .fill(RoutingTheme.warning)
                    .frame(width: 28, height: 28)
                Image(systemName: "figure.stairs")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        case .unknownRamp:
            ZStack {
                Circle()
                    .fill(RoutingTheme.danger)
                    .frame(width: 28, height: 28)
                Text("?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
        case .ramp:
            ZStack {
                Circle()
                    .fill(RoutingTheme.success)
                    .frame(width: 24, height: 24)
                Image(systemName: "figure.roll")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        case .elevator:
            ZStack {
                Circle()
                    .fill(RoutingTheme.accent)
                    .frame(width: 24, height: 24)
                Text("E")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

struct RouteAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType

    enum AnnotationType {
        case stairs, unknownRamp, ramp, elevator
    }
}

// MARK: - Destination Marker

struct DestinationMarker: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(RoutingTheme.danger)
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 12))
                .foregroundColor(RoutingTheme.danger)
                .offset(y: -6)
        }
    }
}

// MARK: - Legend View

struct LegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Baseline - dashed gray
            HStack(spacing: 8) {
                DashedLine()
                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                    .frame(width: 24, height: 3)
                Text("Baseline")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(RoutingTheme.primary)
            }
            // Accessible - solid blue
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(RoutingTheme.accessibleColor)
                    .frame(width: 24, height: 6)
                Text("Accessible-first")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(RoutingTheme.primary)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.97))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4)
    }
}

// MARK: - User Location Marker

struct UserLocationMarker: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(RoutingTheme.accent.opacity(0.2))
                .frame(width: 40, height: 40)
                .scaleEffect(isPulsing ? 1.3 : 1.0)

            Circle()
                .fill(RoutingTheme.accent)
                .frame(width: 16, height: 16)

            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 16, height: 16)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Route Toggle

struct RouteToggleView: View {
    @Binding var selected: AccessibleRoutingDemoView.RouteType

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AccessibleRoutingDemoView.RouteType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selected = type
                    }
                } label: {
                    Text(type.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selected == type ? .white : RoutingTheme.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selected == type ?
                            RoutingTheme.accent : Color.clear
                        )
                        .cornerRadius(10)
                }
            }
        }
        .padding(4)
        .background(Color(hex: "#EDF2F7"))
        .cornerRadius(12)
    }
}

// MARK: - Dashed Line Shape

struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Warning Banner

struct WarningBannerView: View {
    let onConfirmTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Curb ramp status unknown ahead")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            Button(action: onConfirmTap) {
                Text("Confirm")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(RoutingTheme.warning)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoutingTheme.warning)
    }
}

// MARK: - Accuracy Chip

struct AccuracyChipView: View {
    let fix: GnssFix

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 18))
                .foregroundColor(RoutingTheme.warning)

            Text("GPS accuracy low (\u{00B1}\(Int(fix.fixAccuracyM)) m)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(RoutingTheme.warning)

            Spacer()

            Text("Move to open sky")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(RoutingTheme.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoutingTheme.warning.opacity(0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RoutingTheme.warning.opacity(0.4), lineWidth: 1.5)
        )
    }
}

// MARK: - Route Summary

struct RouteSummaryView: View {
    let route: RoutePayload
    var barrierCount: Int = 0

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 16))
                    .foregroundColor(RoutingTheme.accent)
                Text(String(format: "%.2f km", route.summary.distanceKm))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(RoutingTheme.primary)
            }

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 16))
                    .foregroundColor(RoutingTheme.accent)
                Text(String(format: "%.0f min", route.summary.timeMin))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(RoutingTheme.primary)
            }

            Spacer()

            // Barrier chip
            if barrierCount == 0 {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 15))
                    Text("No barriers")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(RoutingTheme.success)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoutingTheme.success.opacity(0.12))
                .cornerRadius(8)
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 15))
                    Text("\(barrierCount) barrier\(barrierCount > 1 ? "s" : "")")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(RoutingTheme.warning)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoutingTheme.warning.opacity(0.12))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Step List

struct StepListView: View {
    let steps: [RouteStep]
    let edges: [RouteEdge]
    var onStepTap: ((Int) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Directions")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(RoutingTheme.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.bottom, 12)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                Button {
                    onStepTap?(index)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        // Step number
                        ZStack {
                            Circle()
                                .fill(RoutingTheme.accent.opacity(0.12))
                                .frame(width: 32, height: 32)
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(RoutingTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(step.text)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(RoutingTheme.primary)
                                    .multilineTextAlignment(.leading)

                                // Warning icon for unknown curb ramp
                                if index < edges.count && edges[index].tags.curbRamp == "unknown" {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(RoutingTheme.warning)
                                }

                                // Stairs icon
                                if index < edges.count && edges[index].tags.stairs == true {
                                    Image(systemName: "figure.stairs")
                                        .font(.system(size: 14))
                                        .foregroundColor(RoutingTheme.warning)
                                }
                            }

                            HStack(spacing: 8) {
                                Text("\(Int(step.distanceM)) m")
                                    .font(.system(size: 14))
                                    .foregroundColor(RoutingTheme.secondary)

                                if index < edges.count, let surface = edges[index].tags.surface {
                                    Text("• \(surface)")
                                        .font(.system(size: 13))
                                        .foregroundColor(RoutingTheme.secondary.opacity(0.8))
                                }

                                Spacer()

                                Image(systemName: "info.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(RoutingTheme.accent.opacity(0.6))
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                if index < steps.count - 1 {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
    }
}

// MARK: - Provenance Footer

struct ProvenanceFooterView: View {
    let provenance: RouteProvenance

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 12))
                .foregroundColor(RoutingTheme.secondary)

            Text("OSM snapshot: \(provenance.osmSnapshot)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(RoutingTheme.secondary)

            Text("•")
                .foregroundColor(RoutingTheme.secondary.opacity(0.5))

            Text("Last confirmed varies")
                .font(.system(size: 12))
                .foregroundColor(RoutingTheme.secondary.opacity(0.8))

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "#F7FAFC"))
        .cornerRadius(8)
    }
}

// MARK: - Tag Tooltip

struct TagTooltipView: View {
    let edge: RouteEdge
    let osmSnapshot: String
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Crossing Details")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(RoutingTheme.primary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(RoutingTheme.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                TagRow(label: "Curb Ramp", value: edge.tags.curbRamp ?? "—",
                       valueColor: edge.tags.curbRamp == "true" ? RoutingTheme.success :
                                   edge.tags.curbRamp == "unknown" ? RoutingTheme.warning : RoutingTheme.danger)
                TagRow(label: "Surface", value: edge.tags.surface ?? "—")
                TagRow(label: "Incline", value: edge.tags.incline != nil ? String(format: "%.0f%%", (edge.tags.incline ?? 0) * 100) : "—")
                TagRow(label: "Stairs", value: edge.tags.stairs == true ? "Yes" : "No",
                       valueColor: edge.tags.stairs == true ? RoutingTheme.warning : RoutingTheme.success)
                TagRow(label: "Elevator", value: edge.tags.elevator == true ? "Yes" : "No")

                Divider()

                TagRow(label: "Last Confirmed", value: edge.lastConfirmed ?? "—")
                TagRow(label: "OSM Snapshot", value: osmSnapshot)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20)
        .padding(24)
    }
}

struct TagRow: View {
    let label: String
    let value: String
    var valueColor: Color = RoutingTheme.primary

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(RoutingTheme.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Confirm Sheet

struct ConfirmCurbRampSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var hasPhoto = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "figure.roll")
                    .font(.system(size: 48))
                    .foregroundColor(RoutingTheme.accent)

                Text("Confirm Curb Ramp")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(RoutingTheme.primary)

                Text("Help improve accessibility data for others")
                    .font(.system(size: 15))
                    .foregroundColor(RoutingTheme.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            VStack(spacing: 12) {
                Button {
                    // Confirm without photo
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Yes, ramp exists")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoutingTheme.success)
                    .cornerRadius(12)
                }

                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("No ramp here")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoutingTheme.danger)
                    .cornerRadius(12)
                }

                Button {
                    // Open camera
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Add photo (optional)")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RoutingTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoutingTheme.accent.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview("Accessible Routing Demo") {
    AccessibleRoutingDemoView()
}

#Preview("Figure C - Tooltip") {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        TagTooltipView(
            edge: RouteEdge(
                id: 1001,
                geometry: RouteGeometry(type: "LineString", coordinates: []),
                lenM: 140, timeS: 120,
                tags: EdgeTags(stairs: false, curbRamp: "true", surface: "asphalt", incline: 0.03, elevator: false),
                lastConfirmed: "2025-07-01", isCrossing: true
            ),
            osmSnapshot: "2025-10-10",
            onClose: {}
        )
    }
}

#Preview("Figure D - Warning Banner") {
    VStack {
        WarningBannerView(onConfirmTap: {})
        Spacer()
    }
}

#Preview("Figure E - Accuracy Chip") {
    AccuracyChipView(fix: GnssFix(lat: 33.7756, lon: -84.3963, fixTime: "", fixAccuracyM: 18.0))
        .padding()
}
