import SwiftUI

/// Filter controls for the Bills Marketplace
struct BillsFilterBarView: View {
    @Binding var selectedCategory: String?
    @Binding var selectedZipPrefix: String?
    @Binding var selectedSort: SortOption

    let categories: [String]
    let onApplyFilters: () async -> Void
    let onClearFilters: () async -> Void

    @State private var showCategoryPicker = false
    @State private var showZipInput = false
    @State private var showSortPicker = false
    @State private var zipInput = ""

    var activeFilterCount: Int {
        var count = 0
        if selectedCategory != nil { count += 1 }
        if selectedZipPrefix != nil { count += 1 }
        if selectedSort != .priceAsc { count += 1 }
        return count
    }

    var body: some View {
        VStack(spacing: 12) {
            // Filter buttons row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Category filter
                    FilterButton(
                        icon: "tag.fill",
                        title: selectedCategory ?? "Category",
                        isActive: selectedCategory != nil
                    ) {
                        showCategoryPicker = true
                    }

                    // ZIP filter
                    FilterButton(
                        icon: "location.fill",
                        title: selectedZipPrefix != nil ? "ZIP: \(selectedZipPrefix!)" : "ZIP Code",
                        isActive: selectedZipPrefix != nil
                    ) {
                        showZipInput = true
                    }

                    // Sort filter
                    FilterButton(
                        icon: selectedSort.icon,
                        title: selectedSort.rawValue,
                        isActive: selectedSort != .priceAsc
                    ) {
                        showSortPicker = true
                    }

                    // Clear filters (if any active)
                    if activeFilterCount > 0 {
                        Button {
                            Task {
                                await onClearFilters()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.subheadline)

                                Text("Clear")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.billixNavyBlue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.billixGoldenAmber.opacity(0.3))
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Active filter count badge
            if activeFilterCount > 0 {
                HStack {
                    Text("\(activeFilterCount) filter\(activeFilterCount == 1 ? "" : "s") active")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)

                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(
                categories: categories,
                selected: $selectedCategory,
                onApply: {
                    Task { await onApplyFilters() }
                    showCategoryPicker = false
                }
            )
            .presentationDetents([.medium])
            .presentationBackground(Color(hex: "#F5F7F6"))
        }
        .sheet(isPresented: $showZipInput) {
            ZipInputSheet(
                zipPrefix: $selectedZipPrefix,
                onApply: {
                    Task { await onApplyFilters() }
                    showZipInput = false
                },
                onClear: {
                    Task { await onClearFilters() }
                    showZipInput = false
                }
            )
            .presentationDetents([.height(250)])
            .presentationBackground(Color(hex: "#F5F7F6"))
        }
        .sheet(isPresented: $showSortPicker) {
            SortPickerSheet(
                selectedSort: $selectedSort,
                onApply: {
                    Task { await onApplyFilters() }
                    showSortPicker = false
                }
            )
            .presentationDetents([.height(300)])
            .presentationBackground(Color(hex: "#F5F7F6"))
        }
    }
}

// MARK: - Filter Button

struct FilterButton: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .foregroundColor(isActive ? .white : .billixNavyBlue)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isActive ? Color.billixMoneyGreen : Color.white)
                    .shadow(
                        color: Color.billixNavyBlue.opacity(0.1),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
        }
    }
}

// MARK: - Category Picker Sheet

struct CategoryPickerSheet: View {
    let categories: [String]
    @Binding var selected: String?
    let onApply: () -> Void

    var body: some View {
        NavigationView {
            List {
                // All categories option
                Button {
                    selected = nil
                    onApply()
                } label: {
                    HStack {
                        Text("All Categories")
                            .foregroundColor(.billixNavyBlue)

                        Spacer()

                        if selected == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.billixMoneyGreen)
                        }
                    }
                }

                ForEach(categories, id: \.self) { category in
                    Button {
                        selected = category
                        onApply()
                    } label: {
                        HStack {
                            Text(category)
                                .foregroundColor(.billixNavyBlue)

                            Spacer()

                            if selected == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.billixMoneyGreen)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - ZIP Input Sheet

struct ZipInputSheet: View {
    @Binding var zipPrefix: String?
    let onApply: () -> Void
    let onClear: () -> Void
    @State private var input: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter ZIP Code")
                    .font(.headline)
                    .foregroundColor(.billixNavyBlue)

                TextField("e.g., 94102", text: $input)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .padding(.horizontal)
                    .onChange(of: input) { oldValue, newValue in
                        // Limit to 5 digits
                        if newValue.count > 5 {
                            input = String(newValue.prefix(5))
                        }
                    }

                // Show extracted prefix if user entered more than 3 digits
                if input.count >= 3 {
                    Text("Searching area: \(String(input.prefix(3)))")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                }

                HStack(spacing: 12) {
                    Button("Clear") {
                        zipPrefix = nil
                        input = ""
                        onClear()
                    }
                    .buttonStyle(.bordered)

                    Button("Apply") {
                        // Extract first 3 digits only
                        if !input.isEmpty {
                            zipPrefix = String(input.prefix(3))
                        } else {
                            zipPrefix = nil
                        }
                        onApply()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.billixMoneyGreen)
                    .disabled(input.isEmpty && zipPrefix == nil)
                }
                .padding()

                Spacer()
            }
            .padding()
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - Sort Picker Sheet

struct SortPickerSheet: View {
    @Binding var selectedSort: SortOption
    let onApply: () -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        selectedSort = option
                        onApply()
                    } label: {
                        HStack {
                            Image(systemName: option.icon)
                                .foregroundColor(.billixMoneyGreen)

                            Text(option.rawValue)
                                .foregroundColor(.billixNavyBlue)

                            Spacer()

                            if selectedSort == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.billixMoneyGreen)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

struct BillsFilterBarView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State var category: String? = nil
        @State var zip: String? = nil
        @State var sort: SortOption = .priceAsc

        var body: some View {
            BillsFilterBarView(
                selectedCategory: $category,
                selectedZipPrefix: $zip,
                selectedSort: $sort,
                categories: ["Electric", "Internet", "Water", "Gas"],
                onApplyFilters: { },
                onClearFilters: { }
            )
            .background(Color.billixCreamBeige.opacity(0.3))
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
