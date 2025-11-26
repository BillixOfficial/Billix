# Camera, Gallery, and Document Picker Setup Instructions

## ✅ Completed

All the code for camera, gallery, and document picker functionality has been implemented:

1. **MediaPickers.swift** - Contains:
   - `ImagePicker` - UIImagePickerController wrapper for camera and photo library
   - `ModernPhotosPicker` - Modern PhotosUI picker
   - `DocumentPicker` - UIDocumentPickerViewController wrapper for files
   - `CameraPermissionHelper` - Helper for checking camera permissions

2. **UploadViewModel** - Updated with:
   - State properties for showing pickers
   - Methods to handle camera, gallery, and document selection
   - Image and document processing logic

3. **UploadHubView** - Updated with:
   - Separate button actions for Camera, Gallery, and Document
   - Sheet presentations for each picker type
   - Integration with the view model

4. **ScanUploadFlowView & ScanUploadViewModel** - Updated to:
   - Accept a preselected image
   - Automatically process the image when provided

## 🔧 Required Manual Steps

### Step 1: Add MediaPickers.swift to Xcode Project

1. Open your Xcode project
2. Right-click on `Billix/Features/Upload/Views/Components` in the Project Navigator
3. Select "Add Files to 'Billix'..."
4. Navigate to the Components folder and select `MediaPickers.swift`
5. Ensure "Copy items if needed" is **unchecked** (file is already in place)
6. Click "Add"

### Step 2: Configure Info.plist Privacy Permissions

You need to add privacy usage descriptions for camera and photo library access:

**In Xcode:**
1. Select your project in the Project Navigator
2. Select the "Billix" target
3. Go to the "Info" tab
4. Click the "+" button to add new keys
5. Add the following keys with their descriptions:

| Key | Value |
|-----|-------|
| `Privacy - Camera Usage Description` | "Billix needs camera access to scan your bills for analysis and savings insights." |
| `Privacy - Photo Library Usage Description` | "Billix needs photo library access to upload your bill images for analysis." |

**Or add to Info.plist directly:**
```xml
<key>NSCameraUsageDescription</key>
<string>Billix needs camera access to scan your bills for analysis and savings insights.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Billix needs photo library access to upload your bill images for analysis.</string>
```

### Step 3: Test on a Real Device

Camera functionality requires a physical device. Test the following:

1. **Camera Button**:
   - Tap the Camera button
   - Grant camera permissions when prompted
   - Take a photo of a bill
   - Verify the scan upload flow starts with your captured image

2. **Gallery Button**:
   - Tap the Gallery button
   - Grant photo library permissions when prompted
   - Select an image from your photo library
   - Verify the scan upload flow starts with your selected image

3. **Document Button**:
   - Tap the Document button
   - Select a PDF or image file from Files app
   - Verify the scan upload flow starts with your selected document

## 📱 How It Works

1. **Camera/Gallery/Document buttons** → Opens respective picker
2. **User selects media** → `handleImageSelected()` or `handleDocumentSelected()` called
3. **Image stored in ViewModel** → `selectedImage` property updated
4. **ScanUploadFlow presented** → Receives the preselected image
5. **Automatic processing** → Image is uploaded and analyzed immediately

## 🔒 Privacy & Security

- All file operations use security-scoped resources
- Documents are copied to temporary location for processing
- Camera and photo library access require explicit user permission
- Permissions are requested at runtime, not app launch

## 📋 Features Implemented

✅ Camera capture with live preview
✅ Photo library selection with modern PhotosUI
✅ Document picker supporting PDF and images
✅ Automatic image processing and upload
✅ Permission handling and error states
✅ Integration with existing ScanUpload flow
