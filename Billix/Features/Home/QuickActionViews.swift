//
//  QuickActionViews.swift
//  Billix
//
//  Views for Quick Action buttons: Add Bill, Scan, Budget
//

import SwiftUI
import PhotosUI

// MARK: - Theme (Shared)

private enum QATheme {
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let accent = Color(hex: "#5B8A6B")
    static let accentLight = Color(hex: "#5B8A6B").opacity(0.08)
    static let success = Color(hex: "#4CAF7A")
    static let warning = Color(hex: "#E8A54B")
    static let danger = Color(hex: "#E07A6B")
    static let info = Color(hex: "#5BA4D4")
    static let purple = Color(hex: "#9B7EB8")
}

// MARK: - Add Bill Action Sheet

struct AddBillActionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showManualEntry = false
    @State private var showPhotoUpload = false
    @State private var showAutoDetect = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(QATheme.accent)

                    Text("Add a Bill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(QATheme.primaryText)

                    Text("Choose how you'd like to add your bill")
                        .font(.system(size: 15))
                        .foregroundColor(QATheme.secondaryText)
                }
                .padding(.top, 20)

                // Options
                VStack(spacing: 12) {
                    AddBillOptionCard(
                        icon: "doc.text.fill",
                        iconColor: QATheme.accent,
                        title: "Manual Entry",
                        subtitle: "Enter bill details yourself",
                        badge: nil
                    ) {
                        showManualEntry = true
                    }

                    AddBillOptionCard(
                        icon: "camera.fill",
                        iconColor: QATheme.info,
                        title: "Scan Bill",
                        subtitle: "Take a photo or upload from gallery",
                        badge: "AI-Powered"
                    ) {
                        showPhotoUpload = true
                    }

                    AddBillOptionCard(
                        icon: "wand.and.stars",
                        iconColor: QATheme.purple,
                        title: "Auto-Detect",
                        subtitle: "Connect your email to find bills",
                        badge: "Coming Soon"
                    ) {
                        // Coming soon
                    }
                    .opacity(0.6)
                    .disabled(true)
                }
                .padding(.horizontal, 20)

                Spacer()

                // Quick tip
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundColor(QATheme.warning)

                    Text("Scanning your bill helps us find savings automatically")
                        .font(.system(size: 13))
                        .foregroundColor(QATheme.secondaryText)
                }
                .padding(14)
                .background(QATheme.warning.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(QATheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(QATheme.accent)
                }
            }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualBillEntryView()
        }
        .sheet(isPresented: $showPhotoUpload) {
            ScanBillView()
        }
    }
}

private struct AddBillOptionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(iconColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(QATheme.primaryText)

                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(badge == "Coming Soon" ? QATheme.secondaryText : QATheme.purple)
                                .cornerRadius(4)
                        }
                    }

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(QATheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(QATheme.secondaryText.opacity(0.5))
            }
            .padding(16)
            .background(QATheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Manual Bill Entry View

struct ManualBillEntryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var billName = ""
    @State private var billAmount = ""
    @State private var selectedCategory: BillCategory = .electric
    @State private var dueDate = Date()
    @State private var isRecurring = true
    @State private var notes = ""

    enum BillCategory: String, CaseIterable, Identifiable {
        case electric = "Electric"
        case gas = "Gas"
        case water = "Water"
        case internet = "Internet"
        case phone = "Phone"
        case streaming = "Streaming"
        case insurance = "Insurance"
        case rent = "Rent/Mortgage"
        case other = "Other"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .electric: return "bolt.fill"
            case .gas: return "flame.fill"
            case .water: return "drop.fill"
            case .internet: return "wifi"
            case .phone: return "iphone"
            case .streaming: return "play.tv.fill"
            case .insurance: return "shield.fill"
            case .rent: return "house.fill"
            case .other: return "doc.fill"
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Bill Details") {
                    TextField("Provider Name", text: $billName)

                    HStack {
                        Text("$")
                            .foregroundColor(QATheme.secondaryText)
                        TextField("Amount", text: $billAmount)
                            .keyboardType(.decimalPad)
                    }

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(BillCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }

                Section("Due Date") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)

                    Toggle("Recurring Monthly", isOn: $isRecurring)
                }

                Section("Notes (Optional)") {
                    TextField("Add notes about this bill...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Add Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(QATheme.secondaryText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBill()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(QATheme.accent)
                    .disabled(billName.isEmpty || billAmount.isEmpty)
                }
            }
        }
    }

    private func saveBill() {
        // TODO: Save bill to Supabase
        print("Saving bill: \(billName) - $\(billAmount)")
        dismiss()
    }
}

// MARK: - Scan Bill View

struct ScanBillView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isAnalyzing = false
    @State private var analysisComplete = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let image = selectedImage {
                    // Show selected image with analysis
                    VStack(spacing: 16) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(QATheme.accent.opacity(0.3), lineWidth: 2)
                            )

                        if isAnalyzing {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Analyzing your bill...")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(QATheme.secondaryText)
                            }
                            .padding(.vertical, 20)
                        } else if analysisComplete {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(QATheme.success)

                                Text("Bill Analyzed!")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(QATheme.primaryText)

                                Text("We found potential savings of $23/month")
                                    .font(.system(size: 14))
                                    .foregroundColor(QATheme.success)
                            }
                            .padding(.vertical, 20)
                        }

                        // Action buttons
                        HStack(spacing: 12) {
                            Button {
                                selectedImage = nil
                                analysisComplete = false
                            } label: {
                                Text("Retake")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(QATheme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(QATheme.accentLight)
                                    .cornerRadius(12)
                            }

                            if !isAnalyzing && !analysisComplete {
                                Button {
                                    analyzeImage()
                                } label: {
                                    Text("Analyze")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(QATheme.accent)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    // Image selection options
                    VStack(spacing: 20) {
                        Spacer()

                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(QATheme.info)

                        Text("Scan Your Bill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(QATheme.primaryText)

                        Text("Take a photo or upload an image of your bill and we'll extract the details automatically")
                            .font(.system(size: 15))
                            .foregroundColor(QATheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer()

                        // Capture options
                        VStack(spacing: 12) {
                            Button {
                                showCamera = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18))
                                    Text("Take Photo")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(QATheme.accent)
                                .cornerRadius(14)
                            }

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack(spacing: 10) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 18))
                                    Text("Choose from Library")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(QATheme.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(QATheme.accentLight)
                                .cornerRadius(14)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .background(QATheme.background)
            .navigationTitle("Scan Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(QATheme.accent)
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                    }
                }
            }
        }
    }

    private func analyzeImage() {
        isAnalyzing = true

        // Simulate AI analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isAnalyzing = false
            analysisComplete = true
        }
    }
}

// MARK: - Camera Image Picker

struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker

        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Budget Overview View

struct BudgetOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var monthlyBudget: Double = 500
    @State private var currentSpend: Double = 324.39

    private var remainingBudget: Double {
        monthlyBudget - currentSpend
    }

    private var progress: Double {
        min(currentSpend / monthlyBudget, 1.0)
    }

    private var isOverBudget: Bool {
        currentSpend > monthlyBudget
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Main budget card
                    VStack(spacing: 20) {
                        // Progress ring
                        ZStack {
                            Circle()
                                .stroke(QATheme.accent.opacity(0.15), lineWidth: 16)
                                .frame(width: 160, height: 160)

                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    isOverBudget ? QATheme.danger : QATheme.accent,
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                )
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 4) {
                                Text("$\(Int(currentSpend))")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(QATheme.primaryText)

                                Text("of $\(Int(monthlyBudget))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(QATheme.secondaryText)
                            }
                        }

                        // Status message
                        HStack(spacing: 8) {
                            Image(systemName: isOverBudget ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .foregroundColor(isOverBudget ? QATheme.danger : QATheme.success)

                            Text(isOverBudget ? "Over budget by $\(Int(abs(remainingBudget)))" : "$\(Int(remainingBudget)) remaining")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(isOverBudget ? QATheme.danger : QATheme.success)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background((isOverBudget ? QATheme.danger : QATheme.success).opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(24)
                    .background(QATheme.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    // Spending breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Spending Breakdown")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(QATheme.secondaryText)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        VStack(spacing: 12) {
                            BudgetCategoryRow(icon: "bolt.fill", name: "Electric", amount: 142.30, color: QATheme.warning)
                            BudgetCategoryRow(icon: "wifi", name: "Internet", amount: 89.99, color: QATheme.info)
                            BudgetCategoryRow(icon: "iphone", name: "Phone", amount: 82.10, color: QATheme.danger)
                            BudgetCategoryRow(icon: "play.tv.fill", name: "Streaming", amount: 10.00, color: QATheme.purple)
                        }
                        .padding(16)
                        .background(QATheme.cardBackground)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)

                    // Edit budget button
                    Button {
                        // TODO: Edit budget
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Adjust Budget")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(QATheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(QATheme.accentLight)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
            .background(QATheme.background)
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(QATheme.accent)
                }
            }
        }
    }
}

private struct BudgetCategoryRow: View {
    let icon: String
    let name: String
    let amount: Double
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .cornerRadius(10)

            Text(name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(QATheme.primaryText)

            Spacer()

            Text("$\(String(format: "%.2f", amount))")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(QATheme.primaryText)
        }
    }
}

// MARK: - Previews

#Preview("Add Bill") {
    AddBillActionSheet()
}

#Preview("Scan Bill") {
    ScanBillView()
}

#Preview("Budget") {
    BudgetOverviewView()
}
