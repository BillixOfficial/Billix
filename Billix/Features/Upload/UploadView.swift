import SwiftUI
import SwiftData

struct UploadView: View {
    @StateObject private var viewModel = UploadViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                Color.billixCreamBeige.ignoresSafeArea()

                switch viewModel.uploadState {
                case .idle, .selecting:
                    idleView
                case .uploading, .analyzing:
                    UploadProgressView(
                        progress: viewModel.progress,
                        message: viewModel.statusMessage,
                        onCancel: {
                            viewModel.reset()
                        }
                    )
                case .success(let analysis):
                    AnalysisResultsView(
                        analysis: analysis,
                        onSave: {
                            // Already saved in ViewModel
                        },
                        onDismiss: {
                            viewModel.reset()
                        }
                    )
                case .error(let error):
                    ErrorView(
                        message: error.message,
                        onRetry: {
                            viewModel.retry()
                        },
                        onDismiss: {
                            viewModel.reset()
                        }
                    )
                }
            }
            .navigationTitle("Upload Bill")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.modelContext = modelContext
            }
            .sheet(isPresented: $viewModel.showDocumentScanner) {
                #if os(iOS)
                DocumentScannerView(scannedImages: Binding(
                    get: { [] },
                    set: { images in
                        if let image = images.first,
                           let data = image.jpegData(compressionQuality: 0.8) {
                            Task {
                                await viewModel.uploadBill(fileData: data, fileName: "scanned_bill.jpg")
                            }
                        }
                        viewModel.showDocumentScanner = false
                    }
                ))
                #endif
            }
            .sheet(isPresented: $viewModel.showCamera) {
                #if os(iOS)
                CameraPicker { data, fileName in
                    Task {
                        await viewModel.uploadBill(fileData: data, fileName: fileName)
                    }
                    viewModel.showCamera = false
                }
                #endif
            }
            .sheet(isPresented: $viewModel.showPhotoPicker) {
                #if os(iOS)
                PhotoPickerView { data, fileName in
                    Task {
                        await viewModel.uploadBill(fileData: data, fileName: fileName)
                    }
                    viewModel.showPhotoPicker = false
                }
                #endif
            }
            .sheet(isPresented: $viewModel.showDocumentPicker) {
                #if os(iOS)
                DocumentPickerView { data, fileName in
                    Task {
                        await viewModel.uploadBill(fileData: data, fileName: fileName)
                    }
                    viewModel.showDocumentPicker = false
                }
                #endif
            }
            .confirmationDialog("Choose Upload Method", isPresented: $viewModel.showUploadOptions, titleVisibility: .visible) {
                Button("Take Photo") {
                    viewModel.selectFromCamera()
                }
                Button("Choose from Photos") {
                    viewModel.selectFromPhotos()
                }
                Button("Browse Files") {
                    viewModel.selectFromFiles()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var idleView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)

                // Animated icon
                Image(systemName: "doc.text.image.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.billixMoneyGreen, Color.billixDarkTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .phaseAnimator([false, true]) { content, phase in
                        content
                            .scaleEffect(phase ? 1.05 : 1.0)
                            .rotationEffect(.degrees(phase ? 2 : -2))
                    } animation: { _ in
                        .spring(duration: 2, bounce: 0.5).repeatForever()
                    }

                // Title and subtitle
                VStack(spacing: 12) {
                    Text("Upload Your Bill")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)

                    Text("Scan or upload a bill to get instant AI analysis and insights")
                        .font(.body)
                        .foregroundColor(.billixDarkTeal)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Primary action - Scan
                VStack(spacing: 16) {
                    Button(action: {
                        viewModel.showDocumentScanner = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.viewfinder.fill")
                                .font(.title3)
                            Text("Scan Bill")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            LinearGradient(
                                colors: [Color.billixMoneyGreen, Color.billixDarkTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color.billixMoneyGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                    }

                    // Secondary action - Other options
                    Button(action: {
                        viewModel.showUploadOptions = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.title3)
                            Text("Other Upload Options")
                                .font(.headline)
                        }
                        .foregroundColor(.billixNavyBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color.white)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.billixMoneyGreen, Color.billixDarkTeal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.billixNavyBlue.opacity(0.1), radius: 5, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 24)

                // Info cards
                VStack(spacing: 16) {
                    InfoCard(
                        icon: "checkmark.shield.fill",
                        title: "Secure & Private",
                        description: "Your bills are encrypted and never shared"
                    )

                    InfoCard(
                        icon: "brain.filled.head.profile",
                        title: "AI-Powered Analysis",
                        description: "Get instant insights and savings opportunities"
                    )

                    InfoCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Track Spending",
                        description: "Monitor your bills and expenses over time"
                    )
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.billixMoneyGreen)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.billixMoneyGreen.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.billixNavyBlue)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.billixDarkTeal)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.billixNavyBlue.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    UploadView()
        .modelContainer(for: StoredBill.self, inMemory: true)
}
