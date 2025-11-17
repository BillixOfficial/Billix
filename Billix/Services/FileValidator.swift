import Foundation

struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
}

/// File validator with magic bytes checking for enhanced security
/// Validates files using binary signatures to prevent malicious uploads
struct FileValidator {
    static let maxFileSize: Int = 10 * 1024 * 1024 // 10MB
    static let minFileSize: Int = 100 // 100 bytes
    static let allowedExtensions = ["pdf", "jpg", "jpeg", "png", "heic"]

    // MARK: - Magic Bytes Signatures
    private static let pdfMagicBytes: [UInt8] = [0x25, 0x50, 0x44, 0x46] // %PDF-
    private static let pngMagicBytes: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    private static let jpegMagicBytes: [UInt8] = [0xFF, 0xD8, 0xFF]
    private static let heicMagicBytes: [UInt8] = [0x66, 0x74, 0x79, 0x70] // ftyp at offset 4

    static func validate(fileData: Data, fileName: String) -> ValidationResult {
        // Check minimum file size
        if fileData.count < minFileSize {
            return ValidationResult(
                isValid: false,
                errorMessage: "File is too small or corrupted"
            )
        }

        // Check maximum file size
        if fileData.count > maxFileSize {
            return ValidationResult(
                isValid: false,
                errorMessage: "File size exceeds 10MB limit"
            )
        }

        // Check file extension
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        if !allowedExtensions.contains(fileExtension) {
            return ValidationResult(
                isValid: false,
                errorMessage: "Invalid file type. Please upload PDF, PNG, JPEG, or HEIC files only"
            )
        }

        // Magic bytes validation (prevents fake file extensions)
        guard validateMagicBytes(fileData) else {
            return ValidationResult(
                isValid: false,
                errorMessage: "File appears to be corrupted or not a valid \(fileExtension.uppercased()) file"
            )
        }

        return ValidationResult(isValid: true, errorMessage: nil)
    }

    // MARK: - Magic Bytes Validation

    private static func validateMagicBytes(_ data: Data) -> Bool {
        guard data.count >= 12 else { return false }

        let header = Array(data.prefix(12))

        // Check PDF signature
        if header.count >= pdfMagicBytes.count &&
           Array(header.prefix(pdfMagicBytes.count)) == pdfMagicBytes {
            return true
        }

        // Check PNG signature
        if header.count >= pngMagicBytes.count &&
           Array(header.prefix(pngMagicBytes.count)) == pngMagicBytes {
            return true
        }

        // Check JPEG signature
        if header.count >= jpegMagicBytes.count &&
           Array(header.prefix(jpegMagicBytes.count)) == jpegMagicBytes {
            return true
        }

        // Check HEIC signature (at offset 4)
        if header.count >= 8 &&
           Array(header[4..<8]) == heicMagicBytes {
            return true
        }

        return false
    }
}
