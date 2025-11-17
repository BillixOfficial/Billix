import SwiftUI
import PhotosUI

#if os(iOS)
struct PhotoPickerView: UIViewControllerRepresentable {
    var onImageSelected: (Data, String) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                parent.dismiss()
                return
            }

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                guard let self = self,
                      let image = object as? UIImage,
                      let imageData = image.jpegData(compressionQuality: 0.8) else {
                    DispatchQueue.main.async {
                        self?.parent.dismiss()
                    }
                    return
                }

                let fileName = "photo-\(Date().timeIntervalSince1970).jpg"
                DispatchQueue.main.async {
                    self.parent.onImageSelected(imageData, fileName)
                    self.parent.dismiss()
                }
            }
        }
    }
}
#endif
