//
//  SwapTimelineView.swift
//  Billix
//
//  Timeline view showing swap events/evidence trail
//

import SwiftUI

// MARK: - Swap Timeline View

struct SwapTimelineView: View {
    // MARK: - Properties

    let swapId: UUID
    @StateObject private var viewModel: SwapTimelineViewModel

    @State private var selectedEvent: SwapEvent?
    @State private var showingExportOptions = false

    // MARK: - Initialization

    init(swapId: UUID) {
        self.swapId = swapId
        _viewModel = StateObject(wrappedValue: SwapTimelineViewModel(swapId: swapId))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            timelineHeader

            if viewModel.isLoading && viewModel.events.isEmpty {
                loadingView
            } else if viewModel.events.isEmpty {
                emptyView
            } else {
                // Timeline content
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.groupedEvents, id: \.date) { group in
                            dateHeader(for: group.date)

                            ForEach(group.events) { event in
                                SwapEventRow(
                                    event: event,
                                    isFirst: event.id == group.events.first?.id,
                                    isLast: event.id == group.events.last?.id
                                )
                                .onTapGesture {
                                    selectedEvent = event
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color.billixCreamBeige)
        .sheet(item: $selectedEvent) { event in
            SwapEventDetailSheet(event: event)
        }
        .confirmationDialog("Export Timeline", isPresented: $showingExportOptions) {
            Button("Export as JSON") {
                Task { await viewModel.exportJSON() }
            }
            Button("Export as Text") {
                Task { await viewModel.exportText() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .task {
            await viewModel.loadEvents()
        }
    }

    // MARK: - Header

    private var timelineHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Evidence Trail")
                    .font(.headline)
                    .foregroundColor(.billixDarkTeal)

                Text("\(viewModel.events.count) events recorded")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Filter button
            Menu {
                Button {
                    viewModel.filterMode = .all
                } label: {
                    Label("All Events", systemImage: viewModel.filterMode == .all ? "checkmark" : "")
                }

                Button {
                    viewModel.filterMode = .significant
                } label: {
                    Label("Key Events Only", systemImage: viewModel.filterMode == .significant ? "checkmark" : "")
                }

                Divider()

                Button {
                    showingExportOptions = true
                } label: {
                    Label("Export...", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundColor(.billixDarkTeal)
            }
        }
        .padding()
        .background(Color.white)
    }

    // MARK: - Date Header

    private func dateHeader(for date: Date) -> some View {
        HStack {
            Text(formatDateHeader(date))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Events Yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Events will appear here as you and your partner take actions.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading timeline...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Swap Event Row

struct SwapEventRow: View {
    let event: SwapEvent
    let isFirst: Bool
    let isLast: Bool

    private var isCurrentUser: Bool {
        event.actorId == SupabaseService.shared.currentUserId
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline line and dot
            timelineIndicator

            // Event content
            eventContent
        }
    }

    // MARK: - Timeline Indicator

    private var timelineIndicator: some View {
        VStack(spacing: 0) {
            // Top line
            Rectangle()
                .fill(isFirst ? Color.clear : Color.billixDarkTeal.opacity(0.3))
                .frame(width: 2, height: 12)

            // Dot
            ZStack {
                Circle()
                    .fill(event.eventType.isSignificant ? Color.billixMoneyGreen : Color.billixDarkTeal.opacity(0.5))
                    .frame(width: 12, height: 12)

                if event.eventType.isSignificant {
                    Circle()
                        .stroke(Color.billixMoneyGreen.opacity(0.3), lineWidth: 4)
                        .frame(width: 20, height: 20)
                }
            }

            // Bottom line
            Rectangle()
                .fill(isLast ? Color.clear : Color.billixDarkTeal.opacity(0.3))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 24)
    }

    // MARK: - Event Content

    private var eventContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with icon and title
            HStack(spacing: 8) {
                Image(systemName: event.eventType.icon)
                    .font(.caption)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(iconColor.opacity(0.1))
                    .cornerRadius(6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.eventType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Text(isCurrentUser ? "You" : "Partner")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(event.createdAt, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Chevron for detail
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Payload preview if available
            if let payload = event.payload {
                payloadPreview(payload)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        .padding(.bottom, 8)
    }

    // MARK: - Payload Preview

    @ViewBuilder
    private func payloadPreview(_ payload: SwapEventPayload) -> some View {
        if let note = payload.note {
            Text(note)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(8)
                .background(Color.billixCreamBeige.opacity(0.5))
                .cornerRadius(8)
        }

        if let proofUrl = payload.proofUrl {
            HStack(spacing: 4) {
                Image(systemName: "photo.fill")
                    .font(.caption)
                Text("Proof attached")
                    .font(.caption)
            }
            .foregroundColor(.billixMoneyGreen)
            .padding(8)
            .background(Color.billixMoneyGreen.opacity(0.1))
            .cornerRadius(8)
        }

        if let amountA = payload.amountA, let amountB = payload.amountB {
            HStack {
                Text("Terms: \(formatAmount(amountA)) ↔ \(formatAmount(amountB))")
                    .font(.caption)
                    .foregroundColor(.billixDarkTeal)
            }
            .padding(8)
            .background(Color.billixDarkTeal.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Helpers

    private var iconColor: Color {
        switch event.eventType {
        case .dealAccepted, .paymentConfirmed, .swapCompleted, .extensionApproved, .collateralReleased:
            return .billixMoneyGreen
        case .dealRejected, .paymentDisputed, .disputeOpened, .collateralForfeited, .swapCancelled:
            return .red
        case .extensionRequested, .extensionDenied, .disputeEscalated:
            return .billixGoldenAmber
        default:
            return .billixDarkTeal
        }
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Event Detail Sheet

struct SwapEventDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let event: SwapEvent

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event header
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: event.eventType.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.billixDarkTeal)
                            .frame(width: 80, height: 80)
                            .background(Color.billixDarkTeal.opacity(0.1))
                            .cornerRadius(20)

                        Text(event.eventType.displayName)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(event.createdAt, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        +
                        Text(" at ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        +
                        Text(event.createdAt, style: .time)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()

                    Divider()

                    // Event details
                    VStack(alignment: .leading, spacing: 16) {
                        detailRow(title: "Event ID", value: event.id.uuidString.prefix(8).description + "...")
                        detailRow(title: "Actor", value: event.actorId == SupabaseService.shared.currentUserId ? "You" : "Partner")
                        detailRow(title: "Type", value: event.eventType.rawValue)

                        if let payload = event.payload {
                            Divider()

                            Text("Event Data")
                                .font(.headline)
                                .foregroundColor(.billixDarkTeal)

                            if let note = payload.note {
                                detailRow(title: "Note", value: note)
                            }

                            if let proofUrl = payload.proofUrl {
                                detailRow(title: "Proof URL", value: proofUrl)
                            }

                            if let dealId = payload.dealId {
                                detailRow(title: "Deal ID", value: dealId.uuidString.prefix(8).description + "...")
                            }

                            if let amountA = payload.amountA {
                                detailRow(title: "Amount A", value: formatAmount(amountA))
                            }

                            if let amountB = payload.amountB {
                                detailRow(title: "Amount B", value: formatAmount(amountB))
                            }
                        }
                    }
                    .padding()

                    // Immutability notice
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.billixMoneyGreen)

                        Text("This event is immutable and cannot be edited or deleted.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.billixMoneyGreen.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .background(Color.billixCreamBeige)
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Timeline ViewModel

@MainActor
class SwapTimelineViewModel: ObservableObject {
    let swapId: UUID

    @Published var events: [SwapEvent] = []
    @Published var groupedEvents: [SwapEventGroup] = []
    @Published var filterMode: FilterMode = .all
    @Published var isLoading = false
    @Published var error: Error?

    enum FilterMode {
        case all
        case significant
    }

    init(swapId: UUID) {
        self.swapId = swapId
    }

    func loadEvents() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedEvents: [SwapEvent]

            switch filterMode {
            case .all:
                fetchedEvents = try await SwapEventService.shared.getEvents(for: swapId)
            case .significant:
                fetchedEvents = try await SwapEventService.shared.getSignificantEvents(for: swapId)
            }

            events = fetchedEvents
            groupedEvents = fetchedEvents.groupedByDate()
        } catch {
            self.error = error
        }
    }

    func exportJSON() async {
        do {
            let data = try await SwapEventService.shared.exportTimelineJSON(for: swapId)
            // TODO: Share the data using UIActivityViewController
            print("JSON exported: \(data.count) bytes")
        } catch {
            self.error = error
        }
    }

    func exportText() async {
        do {
            let text = try await SwapEventService.shared.exportTimelineText(for: swapId)
            // TODO: Share the text using UIActivityViewController
            print("Text exported: \(text.count) characters")
        } catch {
            self.error = error
        }
    }
}

// MARK: - Compact Timeline (for embedding)

struct CompactSwapTimeline: View {
    let events: [SwapEvent]
    let maxEvents: Int

    init(events: [SwapEvent], maxEvents: Int = 3) {
        self.events = events
        self.maxEvents = maxEvents
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.billixDarkTeal)

                Text("Recent Activity")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.billixDarkTeal)

                Spacer()

                if events.count > maxEvents {
                    Text("+ \(events.count - maxEvents) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            ForEach(events.prefix(maxEvents)) { event in
                HStack(spacing: 8) {
                    Image(systemName: event.eventType.icon)
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                        .frame(width: 20)

                    Text(event.eventType.displayName)
                        .font(.caption)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(event.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    SwapTimelineView(swapId: UUID())
}
#endif
