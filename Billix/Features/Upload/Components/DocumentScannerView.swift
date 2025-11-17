import SwiftUI
import VisionKit

#if os(iOS)
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentScannerView

        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                         didFinishWith scan: VNDocumentCameraScan) {
            // Extract all scanned pages
            for pageIndex in 0..<scan.pageCount {
                parent.scannedImages.append(scan.imageOfPage(at: pageIndex))
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                         didFailWithError error: Error) {
            print("Document scanner failed: \(error.localizedDescription)")

            // Error haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            parent.dismiss()
        }
    }
}
#endif

#Preview {
    #if os(iOS)
    struct PreviewWrapper: View {
        @State private var scannedImages: [UIImage] = []
        @State private var showScanner = true

        var body: some View {
            VStack {
                Button("Show Scanner") {
                    showScanner = true
                }
            }
            .sheet(isPresented: $showScanner) {
                DocumentScannerView(scannedImages: $scannedImages)
            }
        }
    }

    return PreviewWrapper()
    #endif
}
